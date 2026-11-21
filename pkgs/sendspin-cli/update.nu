#!/usr/bin/env nu

# Update sources.json for sendspin-cli to the latest release.
# This also updates the dependencies which the CMake build downloads with FetchContent.
# sendspin-cpp-cli pins the sendspin-cpp library in CMakeLists.txt,
# and sendspin-cpp pins the rest of the dependencies in cmake/host.cmake.

const github_raw = "https://raw.githubusercontent.com"

# Prefetch a Git repository and return its fetchgit arguments.
def prefetch [url: string, tag: string, submodules: bool]: nothing -> record {
    let args = if $submodules { [--fetch-submodules] } else { [] }
    let result = (^nix-prefetch-git --quiet --url $url --rev $"refs/tags/($tag)" ...$args | from json)
    {
        url: $url
        tag: $tag
        rev: $result.rev
        hash: $result.hash
        fetchSubmodules: $submodules
    }
}

# Parse the FetchContent_Declare calls in a CMake file.
def parse_declarations []: string -> table {
    $in
    | split row "FetchContent_Declare("
    | skip 1
    | each {|block|
        let lines = (
            $block
            | split row ")"
            | first
            | lines
            | str trim
            | where {|line| $line != "" and not ($line | str starts-with "#") }
        )
        let field = {|key: string|
            $lines
            | where {|line| $line | str starts-with $key }
            | first
            | str replace $key ""
            | str trim
            | split row " "
            | first
        }
        {
            name: ($lines | first | str upcase)
            url: (do $field "GIT_REPOSITORY")
            tag: (do $field "GIT_TAG")
            submodules: ($lines | any {|line| $line | str starts-with "GIT_SUBMODULES" })
        }
    }
}

def main [
    --sources: path = "pkgs/sendspin-cli/sources.json" # The sources file to update
    --force # Update even if the version hasn't changed
] {
    let current = (open $sources)
    let latest = (http get "https://api.github.com/repos/Sendspin/sendspin-cpp-cli/releases/latest" | get tag_name)
    let version = ($latest | str replace --regex '^v' "")
    if $version == $current.version and not $force {
        print $"sendspin-cli is already up to date at ($version)"
        return
    }

    let cli_cmake = (http get --raw $"($github_raw)/Sendspin/sendspin-cpp-cli/($latest)/CMakeLists.txt")
    let sendspin_tag = ($cli_cmake | parse --regex 'set\(SENDSPIN_GIT_TAG "(?<tag>[^"]+)"' | get tag | first)
    let host_cmake = (http get --raw $"($github_raw)/Sendspin/sendspin-cpp/($sendspin_tag)/cmake/host.cmake")

    let dependencies = (
        [{name: "SENDSPIN", url: "https://github.com/Sendspin/sendspin-cpp.git", tag: $sendspin_tag, submodules: false}]
        | append ($host_cmake | parse_declarations)
        | reduce --fold {} {|dependency, acc|
            print $"Prefetching ($dependency.name) ($dependency.tag)"
            $acc | insert $dependency.name (prefetch $dependency.url $dependency.tag $dependency.submodules)
        }
    )

    print $"Prefetching sendspin-cpp-cli ($latest)"
    {
        version: $version
        src: (prefetch "https://github.com/Sendspin/sendspin-cpp-cli.git" $latest false)
        dependencies: $dependencies
    }
    | to json --indent 2
    | save --force $sources
    print $"Updated sendspin-cli from ($current.version) to ($version)"
}

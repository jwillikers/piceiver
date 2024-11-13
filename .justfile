default: build

alias b := build

build target="" *flags="--accept-flake-config":
    #!/usr/bin/env nu
    let target = (
        if ("{{ target }}" | is-empty) {
            if $nu.os-info.arch == "aarch64" {
                "piceiver-sd-image-native"
            } else {
                "piceiver-sd-image"
            }
        } else {
            "{{ target }}"
        }
    )
    ^systemd-inhibit nix build {{ flags }} $".#($target)"

alias ch := check

check: && format
    yamllint .
    asciidoctor *.adoc
    lychee --cache *.html
    nix flake check

alias d := deploy

deploy target="" options="":
    #!/usr/bin/env nu
    let target = (
        if ("{{ target }}" | is-empty) {
            if $nu.os-info.arch == "aarch64" {
                "piceiver-native"
            } else {
                "piceiver"
            }
        } else {
            "{{ target }}"
        }
    )
    ^systemd-inhibit deploy {{ options }} $".#($target)"

flash device:
    zstdcat result/sd-image/nixos-sd-image-*-aarch64-linux.img.zst | sudo dd bs=1M status=progress of={{ device }}

alias fmt := format

format:
    treefmt

alias u := update
alias up := update

update:
    nix flake update

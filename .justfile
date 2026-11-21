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

# Deploy a configuration with deploy-rs, i.e. just deploy snappellite "--hostname snappellite.lan".
deploy target="piceiver" options="":
    systemd-inhibit --what=sleep:shutdown deploy {{ options }} ".#{{ target }}"

# Flash the built SD card image to a device, i.e. just flash /dev/mmcblk0.
flash device:
    zstdcat result/sd-image/*.img.zst | sudo dd bs=4M status=progress conv=fsync of={{ device }}

alias fmt := format

format:
    treefmt

alias u := update
alias up := update

update:
    nix run ".#update-nix-direnv"
    nix run ".#update-nixos-release"
    nix flake update
    nix run ".#update-packages"

# Show the most recent Sendspin pairing code logged by a receiver.
pairing-code host="piceiver.local":
    #!/usr/bin/env bash
    set -euo pipefail
    command="journalctl --grep 'Pairing code' --since -15min --no-pager --output cat"
    message="No pairing code was logged in the last 15 minutes. Start pairing the player in Music Assistant."
    ssh root@{{ host }} "$command || echo '$message'"

# Show the status of the Sendspin player on a receiver.
sendspin-status host="piceiver.local":
    #!/usr/bin/env bash
    set -euo pipefail
    shell=/run/current-system/sw/bin/bash
    ssh root@{{ host }} "machinectl shell --quiet core@ $shell --login -c 'sendspin-cli status'"

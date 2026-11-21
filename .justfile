default: build

# The private repository of secrets, used by the configurations with secrets.
secrets := env("NIX_SECRETS", "../nix-secrets")

alias b := build

# Build the SD card image for a configuration, i.e. just build piceiver.
# The default, piceiver-basic, doesn't need access to the private nix-secrets repository.
build config="piceiver-basic" *flags="--accept-flake-config":
    #!/usr/bin/env nu
    let suffix = if $nu.os-info.arch == "aarch64" { "-sd-image-native" } else { "-sd-image" }
    ^systemd-inhibit nix build {{ flags }} $".#{{ config }}($suffix)"

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

# Store a hashed password for a user in the secrets repository, i.e. just set-password jordan.
set-password user host="piceiver":
    #!/usr/bin/env bash
    set -euo pipefail
    read -rsp "New password for {{ user }}: " first; echo
    read -rsp "Repeat it: " second; echo
    [ "$first" = "$second" ] || { echo "The passwords don't match." >&2; exit 1; }
    printf "%s" "$first" | mkpasswd --method=yescrypt --stdin | tr -d '\n' \
        | jq --raw-input --slurp . \
        | sops set --value-stdin "{{ secrets }}/hosts/shared/{{ host }}/secrets.yaml" '["passwords"]["{{ user }}"]'
    echo "Stored a password hash for {{ user }}. Commit and push the secrets repository to use it."

# Write a host's SSH host keys from the secrets repository to a freshly flashed SD card.
# This must be done before the first boot, i.e. just provision-ssh-host-keys /dev/mmcblk0.
provision-ssh-host-keys device host="piceiver":
    #!/usr/bin/env bash
    set -euo pipefail
    file="{{ secrets }}/hosts/shared/{{ host }}/secrets.yaml"
    partition=$(lsblk --list --noheadings --paths --output NAME,LABEL "{{ device }}" \
        | awk '$2 == "NIXOS_SD" { print $1 }')
    [ -n "$partition" ] || { echo "No NIXOS_SD partition found on {{ device }}." >&2; exit 1; }
    mount=$(mktemp --directory)
    sudo mount "$partition" "$mount"
    trap 'sudo umount "$mount"; rmdir "$mount"' EXIT
    sudo install --directory --mode=755 "$mount/etc/ssh"
    for key in ssh_host_ed25519_key ssh_host_rsa_key; do
        sops decrypt --extract "[\"ssh\"][\"$key\"]" "$file" \
            | sudo install --mode=600 /dev/stdin "$mount/etc/ssh/$key"
        sops decrypt --extract "[\"ssh\"][\"$key.pub\"]" "$file" \
            | sudo install --mode=644 /dev/stdin "$mount/etc/ssh/$key.pub"
    done
    echo "Installed the SSH host keys for {{ host }} on $partition."

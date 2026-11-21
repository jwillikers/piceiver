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

# Save the Sendspin player's identity and pairing records from a receiver to the secrets repository.
# Run this after pairing the player with a new server, i.e. just save-sendspin-state piceiver.local piceiver.
save-sendspin-state address="piceiver.local" host="piceiver":
    #!/usr/bin/env bash
    set -euo pipefail
    file="{{ secrets }}/hosts/shared/{{ host }}/secrets.yaml"
    key='["sendspin-cli"]["state"]'
    remote_state="cat /home/core/.local/state/sendspin-cli/state"
    if cmp --silent <(ssh "root@{{ address }}" "$remote_state") <(sops decrypt --extract "$key" "$file"); then
        echo "The Sendspin player state in the secrets repository is already up to date."
        exit 0
    fi
    ssh "root@{{ address }}" "$remote_state" | jq --raw-input --slurp . | sops set --value-stdin "$file" "$key"
    echo "Saved the Sendspin player state. Commit and push the secrets repository, then update the nix-secrets input."

# Afterwards, commit and push the secrets repository, update the nix-secrets input,
# and deploy before rebooting the host, i.e. just rotate-ssh-host-keys piceiver.local piceiver.
# Rotate a host's SSH host keys, which also changes the age key it decrypts its secrets with.
rotate-ssh-host-keys address="piceiver.local" host="piceiver":
    #!/usr/bin/env bash
    set -euo pipefail
    secrets=$(realpath "{{ secrets }}")
    file="$secrets/hosts/shared/{{ host }}/secrets.yaml"
    staging=/etc/ssh/rotate
    remote() { ssh "root@{{ address }}" "$@"; }

    echo "Generating new SSH host keys in $staging on {{ address }}."
    remote "rm -rf $staging && install --directory --mode=700 $staging \
        && ssh-keygen -q -t ed25519 -N '' -C 'root@{{ host }}' -f $staging/ssh_host_ed25519_key \
        && ssh-keygen -q -t rsa -b 4096 -N '' -C 'root@{{ host }}' -f $staging/ssh_host_rsa_key"

    echo "Storing the new SSH host keys in $file."
    for key in ssh_host_ed25519_key ssh_host_ed25519_key.pub ssh_host_rsa_key ssh_host_rsa_key.pub; do
        remote "cat $staging/$key" | jq --raw-input --slurp . | sops set --value-stdin "$file" "[\"ssh\"][\"$key\"]"
    done

    age_key=$(sops decrypt --extract '["ssh"]["ssh_host_ed25519_key.pub"]' "$file" | ssh-to-age)
    echo "Re-encrypting the secrets for {{ host }} for its new age key, $age_key."
    sed --in-place --regexp-extended "s|(&{{ host }} )age1[a-z0-9]+|\1$age_key|" "$secrets/.sops.yaml"
    grep --quiet "&{{ host }} $age_key" "$secrets/.sops.yaml"
    (cd "$secrets" && for dir in "hosts/shared/{{ host }}" hosts/shared/all; do
        if [ -d "$dir" ]; then find "$dir" -name '*.yaml'; fi
    done | xargs --no-run-if-empty -n 1 sops updatekeys --yes)

    echo "Activating the new SSH host keys on {{ address }}."
    remote "for key in ssh_host_ed25519_key ssh_host_rsa_key; do \
            install --mode=600 $staging/\$key /etc/ssh/\$key \
            && install --mode=644 $staging/\$key.pub /etc/ssh/\$key.pub; \
        done && rm -rf $staging && systemctl restart sshd"

    echo "Updating the known hosts for {{ address }}."
    ssh-keygen -R "{{ address }}" >/dev/null 2>&1 || true
    for key in ssh_host_ed25519_key.pub ssh_host_rsa_key.pub; do
        echo "{{ address }} $(sops decrypt --extract "[\"ssh\"][\"$key\"]" "$file" | cut -d ' ' -f 1,2)"
    done >> ~/.ssh/known_hosts

    echo "Rotated the SSH host keys for {{ host }}."
    echo "Now commit and push the secrets repository, run 'nix flake update nix-secrets', and deploy."
    echo "Until then, rebooting {{ host }} leaves it unable to decrypt its secrets."

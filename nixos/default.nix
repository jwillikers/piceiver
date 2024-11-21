{
  inputs,
  lib,
  modulesPath,
  overlays,
  pkgs,
  role,
  stateVersion,
  username,
  ...
}:
{
  imports = [
    # Use modules from other flakes
    # inputs.disko.nixosModules.disko
    inputs.home-manager.nixosModules.home-manager
    inputs.nix-index-database.nixosModules.nix-index
    inputs.raspberry-pi-nix.nixosModules.raspberry-pi
    inputs.raspberry-pi-nix.nixosModules.sd-image
    # inputs.sops-nix.nixosModules.sops
    (modulesPath + "/installer/scan/not-detected.nix")
    ./_mixins/features
    ./_mixins/services
    ./_mixins/users
  ];

  # Don't install documentation to reduce the size of the final image.
  documentation.enable = false;

  # todo Copy over the flake somehow. Maybe this or sdImage.populateRootCommand
  # environment.etc."nixos".source = ./.;

  environment = {
    # Eject nano and perl from the system
    defaultPackages =
      with pkgs;
      lib.mkForce [
        coreutils-full
        micro
      ];

    systemPackages = with pkgs; [
      sops
      # nix-output-monitor
      # inputs.fh.packages.${platform}.default
      # inputs.nixos-needtoreboot.packages.${platform}.default

      alsa-utils
      bluez-tools
      lm_sensors
      nushell
      raspberrypi-eeprom

      # todo Run this as part of activation?
      # todo Fix cross-compilation of perlPackages.Tk:
      # And allow disabling X11?
      # nix log /nix/store/kyjrc55vk75f09v4f0gpq3fmg6fwhr95-perl5.38.2-Tk-804.036-aarch64-unknown-linux-gnu.drv
      # real_time_config_quick_scan

      tmux
      vim
    ];

    variables = {
      EDITOR = "micro";
      SYSTEMD_EDITOR = "micro";
      VISUAL = "micro";
    };
  };

  home-manager = {
    useGlobalPkgs = true;
    extraSpecialArgs = {
      inherit inputs role stateVersion;
      username = "core";
    };
    users.core = import ../home-manager;
  };

  # Otherwise, the realtime overlay doesn't take.
  # Probably because it needs to be evaluated after tho raspberry-pi-nix module.
  nixpkgs.overlays = [
    overlays.allow-missing-modules
    overlays.ccache
    overlays.realtime
  ];

  programs = {
    command-not-found.enable = false;
    fish = {
      enable = true;
      shellAliases = {
        nano = "micro";
      };
    };
    nano.enable = lib.mkDefault false;
    nix-index-database.comma.enable = true;
  };

  security = {
    sudo.enable = false;
    sudo-rs = {
      enable = true;
      execWheelOnly = true;
      # extraConfig = ''
      #   %wheel \${config.hostname} = NOPASSWD: /usr/bin/poweroff , /usr/bin/systemctl poweroff , /usr/bin/reboot , /usr/bin/systemctl reboot , /usr/bin/systemctl suspend
      #   \${username} \${config.hostname} = NOPASSWD: /usr/bin/sudo -H -u core fish -c 'cd; fish'
      # '';
      extraRules = [
        {
          commands = [
            {
              command = "${pkgs.systemd}/bin/systemctl poweroff";
              options = [ "NOPASSWD" ];
            }
            {
              command = "${pkgs.systemd}/bin/systemctl reboot";
              options = [ "NOPASSWD" ];
            }
            {
              command = "${pkgs.systemd}/bin/systemctl suspend";
              options = [ "NOPASSWD" ];
            }
            {
              command = "${pkgs.systemd}/bin/poweroff";
              options = [ "NOPASSWD" ];
            }
            {
              command = "${pkgs.systemd}/bin/reboot";
              options = [ "NOPASSWD" ];
            }
          ];
          # host = "ALL";
          # host = config.networking.fqdn;
          users = [ username ];
          # }
          # {
          #   commands = [
          #     # todo Test if this works.
          #     # Need EXEC option?
          #     # sudo -H -u core fish -c 'cd; fish'
          #     {
          #       command = "${pkgs.lib.getExe pkgs.fish} -c 'cd; fish'";
          #       options = [ "NOPASSWD" "SETENV" ];
          #     }
          #     {
          #       command = "${pkgs.lib.getExe pkgs.fish}";
          #       options = [ "NOPASSWD" "SETENV" ];
          #     }
          #   ];
          #   # host = config.networking.fqdn;
          #   # host = "ALL";
          #   # runAs = "core:core";
          #   runAs = "core";
          #   users = [username];
        }
      ];
    };
  };

  # services = {
  # todo Fix
  #  > Did not find CMake 'cmake'
  #  > Found CMake: NO
  #  > Run-time dependency gnutls found: NO (tried pkgconfig)
  #  >
  #  > meson.build:299:9: ERROR: Dependency "gnutls" not found, tried pkgconfig
  # fwupd.enable = true;
  # No smartd devices enabled when running on SD card... causing service to fail.
  #   smartd.enable = true;
  # };

  systemd.tmpfiles.rules = [
    "d /nix/var/nix/profiles/per-user/${username} 0755 ${username} root"
    "d /var/lib/private/sops/age 0750 root root"
  ];

  system = {
    inherit stateVersion;
  };
}

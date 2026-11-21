{
  description = "Pi 2.1 channel stereo receiver";

  nixConfig = {
    extra-substituters = [
      "https://nix-community.cachix.org"
      "https://nixos-raspberrypi.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI="
    ];
  };

  inputs = {
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        utils.follows = "flake-utils";
      };
    };
    # todo Actually use disko?
    # disko = {
    #   url = "github:nix-community/disko";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
    flake-utils.url = "github:numtide/flake-utils";
    # todo Look into musnix: https://github.com/musnix/musnix
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # todo This is probably unnecessary here.
    # But it should make it easier
    nix-index-database = {
      url = "github:Mic92/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-update-scripts = {
      url = "github:jwillikers/nix-update-scripts";
      inputs = {
        flake-utils.follows = "flake-utils";
        nixpkgs.follows = "nixpkgs";
        pre-commit-hooks.follows = "pre-commit-hooks";
        treefmt-nix.follows = "treefmt-nix";
      };
    };
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-raspberrypi = {
      url = "github:nvmd/nixos-raspberrypi/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Private repository of secrets encrypted with sops.
    # Only the configurations with secrets use it, so the basic configurations build without access to it.
    nix-secrets = {
      url = "git+ssh://git@forgejo.jwillikers.io/jwillikers/nix-secrets.git?shallow=1";
      flake = false;
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # todo Should I use nixos-hardware?
    # nixos-hardware.url = "github:nixos/nixos-hardware";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      # deadnix: skip
      self,
      deploy-rs,
      flake-utils,
      nix-update-scripts,
      nixos-raspberrypi,
      nixpkgs,
      pre-commit-hooks,
      treefmt-nix,
      ...
    }@inputs:
    let
      overlays = import ./overlays { inherit inputs; };
      overlaysList = with overlays; [
        additions
        ccache
        modifications
        cross-fixes
        allow-missing-modules
        realtime
        unstablePackages
        shairport-sync-airplay2
      ];
      # nixos-raspberrypi's nixosSystem sets nixpkgs.hostPlatform to aarch64-linux and injects the vendor kernel and firmware overlays.
      # Don't pass a pre-built pkgs here, otherwise nixpkgs.overlays, including nixos-raspberrypi's, are ignored.
      mkRaspberryPiSystem =
        {
          config,
          cross ? false,
          # Use secrets from the private nix-secrets repository.
          secrets ? false,
        }:
        nixos-raspberrypi.lib.nixosSystem {
          inherit nixpkgs;
          specialArgs = {
            inherit inputs overlays stateVersion;
            useSecrets = secrets;
            inherit (config)
              audioHAT
              hostname
              raspberryPiModel
              role
              username
              ;
          };
          modules = [
            ./nixos
            {
              nixpkgs = {
                overlays = lib.mkAfter overlaysList;
              }
              // lib.optionalAttrs cross { buildPlatform = "x86_64-linux"; };
            }
          ];
        };
      inherit (nixpkgs) lib;
      piceiverRaspberryPi5Config = {
        audioHAT = "DigiAmp+";
        hostname = "piceiver";
        raspberryPiModel = "5";
        role = "piceiver";
        username = "jordan";
      };
      # Snapcast client satellite for the Raspberry Pi 4.
      snappelliteRaspberryPi4Config = {
        audioHAT = "DAC Pro";
        hostname = "snappellite";
        raspberryPiModel = "4";
        role = "snappellite";
        username = "jordan";
      };
      # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
      stateVersion = "24.05";
    in
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        pre-commit = pre-commit-hooks.lib.${system}.run (
          import ./pre-commit-hooks.nix { inherit pkgs treefmtEval; }
        );
        treefmtEval = treefmt-nix.lib.evalModule pkgs ./treefmt.nix;
      in
      with pkgs;
      {
        # todo I should add the overlays as an output, but they must be outside eachDefaultSystem.
        # inherit overlays;
        apps = {
          inherit (nix-update-scripts.apps.${system}) update-nix-direnv update-nixos-release;
          # Update the packages in pkgs/ which pin their sources.
          update-packages = {
            type = "app";
            program = builtins.toString (
              pkgs.writeShellScript "update-packages" ''
                export PATH=${
                  lib.makeBinPath [
                    pkgs.git
                    pkgs.nix-prefetch-git
                    pkgs.nushell
                  ]
                }:$PATH
                nu ${./pkgs/sendspin-cli/update.nu} "$@"
                ${lib.getExe treefmtEval.config.build.wrapper}
              ''
            );
          };
        };
        devShells.default = mkShell {
          inherit (pre-commit) shellHook;
          nativeBuildInputs =
            with pkgs;
            [
              asciidoctor
              pkgs.deploy-rs
              fish
              jq
              just
              lychee
              mkpasswd
              sops
              ssh-to-age
              zstd
              treefmtEval.config.build.wrapper
            ]
            # Make formatters available for IDE's.
            ++ (builtins.attrValues treefmtEval.config.build.programs)
            ++ pre-commit.enabledPackages;
        };
        formatter = treefmtEval.config.build.wrapper;
        packages = {
          # The basic image builds without access to the private nix-secrets repository.
          default = self.packages.${system}.piceiver-basic-sd-image;
          piceiver-basic-sd-image = self.nixosConfigurations.piceiver-basic.config.system.build.sdImage;
          piceiver-basic-sd-image-native =
            self.nixosConfigurations.piceiver-basic-native.config.system.build.sdImage;
          piceiver-sd-image = self.nixosConfigurations.piceiver.config.system.build.sdImage;
          piceiver-sd-image-native = self.nixosConfigurations.piceiver-native.config.system.build.sdImage;
          snappellite-sd-image = self.nixosConfigurations.snappellite.config.system.build.sdImage;
          snappellite-sd-image-native =
            self.nixosConfigurations.snappellite-native.config.system.build.sdImage;
        };
        # pkgs = pkgsArmCross;
      }
    )
    // {
      inherit overlays;
      checks = builtins.mapAttrs (_system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
      deploy = {
        nodes = {
          piceiver = {
            hostname = "piceiver.local";
            profiles.system = {
              path = deploy-rs.lib.aarch64-linux.activate.nixos self.nixosConfigurations.piceiver;
            };
          };
          # The basic configuration has no SSH keys for root.
          # Connect as the regular user and prompt for its sudo password instead.
          piceiver-basic = {
            hostname = "piceiver.local";
            interactiveSudo = true;
            sshUser = "jordan";
            profiles.system = {
              path = deploy-rs.lib.aarch64-linux.activate.nixos self.nixosConfigurations.piceiver-basic;
              user = "root";
            };
          };
          # piceiver-native = {
          #   hostname = "piceiver.local";
          #   profiles.system.path = deploy-rs.lib.aarch64-linux.activate.nixos self.nixosConfigurations.piceiver-native;
          # };
          # The Snappellite doesn't use secrets yet, so it has no SSH keys for root either.
          snappellite = {
            hostname = "snappellite.local";
            interactiveSudo = true;
            sshUser = "jordan";
            profiles.system = {
              path = deploy-rs.lib.aarch64-linux.activate.nixos self.nixosConfigurations.snappellite;
              user = "root";
            };
          };
          # snappellite-native = {
          #   hostname = "snappellite.local";
          #   profiles.system.path = deploy-rs.lib.aarch64-linux.activate.nixos self.nixosConfigurations.snappellite-native;
          # };
        };
        sshUser = "root";
        # Root may only log in from the local network.
        # piceiver.local can resolve to a global IPv6 address, so connect over IPv4.
        sshOpts = [
          "-o"
          "AddressFamily=inet"
        ];
      };
      nixosConfigurations = {
        # These use secrets from the private nix-secrets repository.
        piceiver = mkRaspberryPiSystem {
          config = piceiverRaspberryPi5Config;
          cross = true;
          secrets = true;
        };
        piceiver-native = mkRaspberryPiSystem {
          config = piceiverRaspberryPi5Config;
          secrets = true;
        };
        # These don't use any secrets and have default passwords.
        piceiver-basic = mkRaspberryPiSystem {
          config = piceiverRaspberryPi5Config;
          cross = true;
        };
        piceiver-basic-native = mkRaspberryPiSystem { config = piceiverRaspberryPi5Config; };
        snappellite = mkRaspberryPiSystem {
          config = snappelliteRaspberryPi4Config;
          cross = true;
        };
        snappellite-native = mkRaspberryPiSystem { config = snappelliteRaspberryPi4Config; };
        # todo Provide builds of the Snappellite image which use the mainline Linux kernel.
        # snappellite-mainline = nixosSystemFull {
        #   pkgs = pkgsArmCross;
        #   specialArgs = {
        #     inherit inputs overlays stateVersion;
        #     inherit (snappelliteRaspberryPi4Config) audioHAT hostname raspberryPiModel role username;
        #   };
        #   modules = [ ./nixos ];
        # };
        # snappellite-mainline-native = nixosSystemFull {
        #   pkgs = pkgsArmNative;
        #   specialArgs = {
        #     inherit inputs overlays stateVersion;
        #     inherit (snappelliteRaspberryPi4Config) audioHAT hostname raspberryPiModel role username;
        #   };
        #   modules = [ ./nixos ];
        # };
      };
    };
}

{
  description = "Pi 2.1 channel stereo receiver";

  nixConfig = {
    extra-substituters = [ "https://nix-community.cachix.org" ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
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
      # todo Use upstream when my fixes get merged for cross-compiling Mopidy with plugins.
      # url = "github:nix-community/home-manager/release-24.05";
      url = "github:jwillikers/home-manager/mopidy-fixes";
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
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        nixpkgs-stable.follows = "nixpkgs";
      };
    };
    raspberry-pi-nix = {
      url = "github:nix-community/raspberry-pi-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # todo Use sops-nix for secret management.
    # The user login password, Jellyfin server credentials, and Net-SNMP accounts all need to be stored as secrets.
    # https://unmovedcentre.com/posts/secrets-management/
    # secrets = {
    #   url = "git+ssh://git@codeberg.org/jwillikers/nix-secrets.git?shallow=1";
    #   flake = false;
    # };
    # sops-nix = {
    #   url = "github:Mic92/sops-nix";
    #   inputs.nixpkgs.follows = "nixpkgs";
    #   inputs.nixpkgs-stable.follows = "nixpkgs";
    # };
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
      nixpkgs,
      pre-commit-hooks,
      # secrets,
      # sops-nix,
      treefmt-nix,
      ...
    }@inputs:
    let
      overlays = import ./overlays { inherit inputs; };
      overlaysList = with overlays; [
        additions
        headless
        mopidy-pipewire-gstreamer-plugin
        rygel-pipewire-gstreamer-plugin
        realtime
        shairport-sync-airplay2
        unstablePackages
      ];
      pkgsArmCross = import nixpkgs {
        # inherit system;
        system = "x86_64-linux";
        crossSystem.config = "aarch64-unknown-linux-gnu";
        overlays = overlaysList;
      };
      pkgsArmNative = import nixpkgs {
        overlays = overlaysList;
        system = "aarch64-linux";
      };
      inherit (nixpkgs.lib) nixosSystem;
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
          inherit (nix-update-scripts.apps.${system}) update-nix-direnv;
          inherit (nix-update-scripts.apps.${system}) update-nixos-release;
        };
        devShells.default = mkShell {
          inherit (pre-commit) shellHook;
          nativeBuildInputs =
            with pkgs;
            [
              asciidoctor
              # colmena.packages.${system}.colmena
              pkgs.deploy-rs
              fish
              just
              lychee
              zstd
              treefmtEval.config.build.wrapper
              # Make formatters available for IDE's.
              (builtins.attrValues treefmtEval.config.build.programs)
            ]
            ++ pre-commit.enabledPackages;
        };
        formatter = treefmtEval.config.build.wrapper;
        packages = {
          default = self.packages.${system}.piceiver-sd-image;
          piceiver-sd-image = self.nixosConfigurations.piceiver.config.system.build.sdImage;
          piceiver-sd-image-native = self.nixosConfigurations.piceiver-native.config.system.build.sdImage;
          snappellite-sd-image = self.nixosConfigurations.snappellite.config.system.build.sdImage;
          snappellite-sd-image-native =
            self.nixosConfigurations.snappellite-native.config.system.build.sdImage;
        };
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
          # piceiver-native = {
          #   hostname = "piceiver.local";
          #   profiles.system.path = deploy-rs.lib.aarch64-linux.activate.nixos self.nixosConfigurations.piceiver-native;
          # };
          snappellite = {
            hostname = "snappellite.local";
            profiles.system.path = deploy-rs.lib.aarch64-linux.activate.nixos self.nixosConfigurations.snappellite;
          };
          # snappellite-native = {
          #   hostname = "snappellite.local";
          #   profiles.system.path = deploy-rs.lib.aarch64-linux.activate.nixos self.nixosConfigurations.snappellite-native;
          # };
        };
        sshUser = "root";
      };
      nixosConfigurations = {
        piceiver = nixosSystem {
          pkgs = pkgsArmCross;
          specialArgs = {
            inherit inputs overlays stateVersion;
            inherit (piceiverRaspberryPi5Config)
              audioHAT
              hostname
              raspberryPiModel
              role
              username
              ;
          };
          modules = [ ./nixos ];
        };
        piceiver-native = nixosSystem {
          pkgs = pkgsArmNative;
          specialArgs = {
            inherit inputs overlays stateVersion;
            inherit (piceiverRaspberryPi5Config)
              audioHAT
              hostname
              raspberryPiModel
              role
              username
              ;
          };
          modules = [ ./nixos ];
        };
        snappellite = nixosSystem {
          pkgs = pkgsArmCross;
          specialArgs = {
            inherit inputs overlays stateVersion;
            inherit (snappelliteRaspberryPi4Config)
              audioHAT
              hostname
              raspberryPiModel
              role
              username
              ;
          };
          modules = [ ./nixos ];
        };
        snappellite-native = nixosSystem {
          pkgs = pkgsArmNative;
          specialArgs = {
            inherit inputs overlays stateVersion;
            inherit (snappelliteRaspberryPi4Config)
              audioHAT
              hostname
              raspberryPiModel
              role
              username
              ;
          };
          modules = [ ./nixos ];
        };
        # todo Provide builds of the Snappellite image which use the mainline Linux kernel.
        # snappellite-mainline = nixosSystem {
        #   pkgs = pkgsArmCross;
        #   specialArgs = {
        #     inherit inputs overlays stateVersion;
        #     inherit (snappelliteRaspberryPi4Config) audioHAT hostname raspberryPiModel role username;
        #   };
        #   modules = [ ./nixos ];
        # };
        # snappellite-mainline-native = nixosSystem {
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

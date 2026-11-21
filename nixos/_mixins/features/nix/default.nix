{
  pkgs,
  config,
  inputs,
  lib,
  username,
  ...
}:
let
  # Skip the private nix-secrets repository by name before checking its type.
  # Checking its type would fetch it, which isn't possible without access to it, i.e. for the basic configurations.
  flakeInputs = lib.filterAttrs (
    name: input: name != "nix-secrets" && lib.isType "flake" input
  ) inputs;
in
{
  nix = {
    # Use Lix from nixpkgs.
    package = pkgs.lixPackageSets.stable.lix;
    gc = {
      automatic = true;
      dates = "Mon *-*-* 03:03:00";
      options = "--delete-older-than 30d";
    };
    settings = {
      accept-flake-config = true;
      auto-optimise-store = true;
      experimental-features = "flakes nix-command";
      # Disable global registry
      flake-registry = "";
      # Workaround for https://github.com/NixOS/nix/issues/9574
      nix-path = config.nix.nixPath;
      trusted-users = [
        "root"
        "${username}"
      ];
      warn-dirty = false;
    };
    # Disable channels
    channel.enable = false;
    # Make flake registry and nix path match flake inputs
    # registry = lib.mapAttrs (_: flake: { inherit flake; }) flakeInputs;
    nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;
  };
}

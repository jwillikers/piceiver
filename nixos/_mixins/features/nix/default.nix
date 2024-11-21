{
  config,
  inputs,
  lib,
  username,
  ...
}:
let
  flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
in
{
  nix = {
    gc = {
      automatic = true;
      dates = "Mon *-*-* 03:03:00";
      options = "--delete-older-than 30d";
    };
    settings = {
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
    registry = lib.mapAttrs (_: flake: { inherit flake; }) flakeInputs;
    nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;
  };
}

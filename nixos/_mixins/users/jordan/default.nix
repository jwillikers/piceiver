{ lib, useSecrets, ... }:
{
  users.users.jordan = {
    description = "Jordan Williams";
    # With secrets, the password is set from the nix-secrets repository in nixos/_mixins/features/sops.
    initialPassword = lib.mkIf (!useSecrets) "opW6&Aa";
  };
}

{ lib, useSecrets, ... }:
{
  users.users.root = {
    # With secrets, the password is set from the nix-secrets repository in nixos/_mixins/features/sops.
    initialPassword = lib.mkIf (!useSecrets) "V2psT!t0";
  };
}

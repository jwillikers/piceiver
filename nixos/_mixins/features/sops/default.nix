{
  config,
  hostname,
  inputs,
  lib,
  useSecrets,
  ...
}:
# Secrets are stored in the private nix-secrets repository and decrypted on the host with sops-nix.
# Configurations without secrets, i.e. piceiver-basic, don't use the nix-secrets repository at all.
# The definitions below depend on useSecrets instead of the config, since the sops options only exist when the module is imported.
{
  imports = lib.optional useSecrets inputs.sops-nix.nixosModules.sops;
}
// lib.optionalAttrs useSecrets {
  sops = {
    defaultSopsFile = "${inputs.nix-secrets}/hosts/shared/${hostname}/secrets.yaml";
    # The host decrypts secrets with the age key derived from its SSH host key.
    # The SSH host keys are also stored in the secrets file so that they can be restored on a new SD card.
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    secrets = {
      "passwords/jordan".neededForUsers = true;
      "passwords/root".neededForUsers = true;
      # The Sendspin player's identity and pairing records.
      # It's copied into the player's state directory when missing, so that Music Assistant doesn't have to pair again.
      "sendspin-cli/state".owner = "core";
    };
  };
  users.users =
    let
      # Public SSH keys are kept out of this public repository, so that images built by others don't grant access.
      authorizedKeys = "${inputs.nix-secrets}/hosts/shared/${hostname}/authorized_keys";
    in
    {
      jordan = {
        hashedPasswordFile = config.sops.secrets."passwords/jordan".path;
        openssh.authorizedKeys.keyFiles = [ "${authorizedKeys}/jordan" ];
      };
      root = {
        hashedPasswordFile = config.sops.secrets."passwords/root".path;
        openssh.authorizedKeys.keyFiles = [ "${authorizedKeys}/root" ];
      };
    };
}

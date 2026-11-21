{ pkgs, useSecrets, ... }:
{
  environment.systemPackages = with pkgs; [ ssh-to-age ];
  services.openssh = {
    enable = true;
    settings = {
      ClientAliveCountMax = 4;
      ClientAliveInterval = 90;
      # With keyboard-interactive authentication, PAM accepts passwords even when password authentication is disabled.
      KbdInteractiveAuthentication = false;
      # Without secrets, there are no SSH keys, so allow the regular user to log in with the default password.
      # With secrets, only SSH keys from the nix-secrets repository are accepted.
      PasswordAuthentication = !useSecrets;
      # Root may only log in with an SSH key, which the nix-secrets repository restricts to the local network.
      # todo Prevent logging in as root entirely once the image is finalized and working as expected.
      # Deploy as the regular user with sudo instead.
      PermitRootLogin = "prohibit-password";
    };
  };
}

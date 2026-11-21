{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [ ssh-to-age ];
  services.openssh = {
    enable = true;
    settings = {
      ClientAliveCountMax = 4;
      ClientAliveInterval = 90;
      # Both are needed to prevent password logins.
      # With keyboard-interactive authentication, PAM still accepts passwords.
      KbdInteractiveAuthentication = false;
      PasswordAuthentication = false;
      # Root may only log in with an SSH key, which is restricted to the local network in nixos/_mixins/users/root.
      # todo Prevent logging in as root entirely once the image is finalized and working as expected.
      # Deploy as the regular user with sudo instead.
      PermitRootLogin = "prohibit-password";
    };
  };
}

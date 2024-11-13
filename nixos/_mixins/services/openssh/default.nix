{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [ ssh-to-age ];
  services.openssh = {
    enable = true;
    settings = {
      ClientAliveCountMax = 4;
      ClientAliveInterval = 90;
      PasswordAuthentication = false;
      PermitRootLogin = "prohibit-password";
    };
  };
}

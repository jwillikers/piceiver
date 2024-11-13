{ pkgs, username, ... }:
{
  services.tailscale = {
    enable = true;
    extraUpFlags = [ "--operator=${username}" ];
    extraSetFlags = [ "--operator=${username}" ];
    openFirewall = true;
    package = pkgs.unstable.tailscale;
  };
}

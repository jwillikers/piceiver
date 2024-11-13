{
  config,
  hostname,
  lib,
  username,
  ...
}:
{
  networking = {
    firewall.enable = true;
    domain = "lan.jwillikers.io";
    hostName = "${hostname}";
    dhcpcd.enable = false;
    networkmanager = {
      enable = true;
      # Don't pull in insane dependencies through the NetworkManager plugins.
      plugins = lib.mkForce [ ];
      unmanaged = [ "tailscale0" ];
      wifi = {
        backend = "iwd";
        powersave = false;
      };
    };
    nftables.enable = true;
    wireless = {
      enable = false;
      iwd.enable = true;
      userControlled.enable = false;
    };
  };
  services = {
    avahi = {
      enable = true;
      ipv6 = true;
      nssmdns4 = true;
      publish = {
        addresses = true;
        enable = true;
        userServices = true;
      };
    };
    # Use resolved for DNS resolution; tailscale MagicDNS requires it
    resolved = {
      dnssec = "true";
      enable = true;
      # Disable mDNS in resolved since Avahi is being used.
      extraConfig = ''
        MulticastDNS=false
      '';
      llmnr = "false";
    };
  };

  # todo Not sure if this will be necessary or not.
  # Belt and braces disable WiFi power saving
  # systemd.services.disable-wifi-powersave =
  #   lib.mkIf
  #     (
  #       lib.isBool config.networking.networkmanager.wifi.powersave
  #       && config.networking.networkmanager.wifi.powersave
  #     )
  #     {
  #       wantedBy = [ "multi-user.target" ];
  #       path = [ pkgs.iw ];
  #       script = ''
  #         iw dev wlan0 set power_save off
  #       '';
  #     };

  # Workaround https://github.com/NixOS/nixpkgs/issues/180175
  systemd.services.NetworkManager-wait-online.enable = lib.mkIf config.networking.networkmanager.enable false;

  users.users.${username}.extraGroups = lib.optionals config.networking.networkmanager.enable [
    "networkmanager"
  ];
}

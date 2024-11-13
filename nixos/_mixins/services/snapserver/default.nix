{
  lib,
  pkgs,
  role,
  ...
}:
lib.mkIf (role == "piceiver") {
  services.snapserver = {
    buffer = 100;
    codec = "pcm";
    enable = true;
    http.docRoot = pkgs.unstable.snapweb; # todo Remove this in 24.11 where it should be the default.
    openFirewall = true;
    sampleFormat = "48000:16:2";
    streams = {
      "Piceiver" = {
        location = "127.0.0.1:4711"; # todo Use IPv6 here when Snapcast supports it.
        query.mode = "client";
        type = "tcp";
      };
    };
  };
  # Open firewall ports specific to Music Assistant
  networking.firewall.allowedTCPPortRanges = [
    {
      from = 4953;
      to = 5153;
    }
  ];
}

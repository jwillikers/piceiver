{
  lib,
  pkgs,
  role,
  ...
}:
lib.mkIf (role == "piceiver") {
  services.snapserver = {
    # For responsiveness, the buffer needs to probably be as low as 100ms at least or you'll notice the pause while it buffers before playing a song.
    # Wired-only: 50ms is too low, but 75ms works well.
    # Wireless: 300ms seems to work pretty well for this case.
    # I still might need to tweak it a bit.
    buffer = 300; # Minimum is 20ms, default is 1000ms
    codec = "pcm";
    enable = true;
    openFirewall = true;
    sampleFormat = "48000:16:2";
    streams = {
      default = {
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

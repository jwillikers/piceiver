{ lib, role, ... }:
lib.mkIf (role == "piceiver") {
  # Shairport is run as a user service provided by the Home Manager configuration.
  boot.kernel.sysctl = {
    "net.ipv4.ip_unprivileged_port_start" = 319;
  };
  environment.etc."shairport-sync.conf".text = ''
    general = {
      default_airplay_volume = -14.0;
      high_threshold_airplay_volume = -6.0;
      mdns_backend = "avahi";
      output_backend = "pw";
    };
    pw = {
      sink_target = "snapserver";
    };
    sessioncontrol = {
      session_timeout = 20;
    };
    diagnostics = {
      log_verbosity = 1;
    };
  '';
  networking.firewall = {
    allowedTCPPorts = [
      3689
      5000
      7000
      5353
    ];
    allowedUDPPorts = [
      319
      320
      5353
    ];
    allowedTCPPortRanges = [
      {
        from = 32768;
        to = 60999;
      }
    ];
    allowedUDPPortRanges = [
      {
        from = 6001;
        to = 6009;
      }
      {
        from = 32768;
        to = 60999;
      }
    ];
  };
}

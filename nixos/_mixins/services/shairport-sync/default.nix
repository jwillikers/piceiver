{ lib, role, ... }:
lib.mkIf (role == "piceiver") {
  # Shairport is run as a user service provided by the Home Manager configuration.
  boot.kernel.sysctl = {
    "net.ipv4.ip_unprivileged_port_start" = 319;
  };
  #  I'm still tweaking the volume controls to get things just right.
  # Because this sends audio to Snapcast, the volume is generously scaled up so as not to be too quiet.
  environment.etc."shairport-sync.conf".text = ''
    general = {
      // Seems like 50ms works fine here.
      // 0.35 is the default for the pa backend.
      audio_backend_buffer_desired_length_in_seconds = 0.05;
      default_airplay_volume = -12.0;
      high_threshold_airplay_volume = -8.0;
      high_volume_idle_timeout_in_minutes = 180;
      mdns_backend = "avahi";
      output_backend = "pw";
      volume_control_profile = "dasl_tapered";
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

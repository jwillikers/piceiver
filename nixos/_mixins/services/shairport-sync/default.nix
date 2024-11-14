{ lib, role, ... }:
lib.mkIf (role == "piceiver") {
  # Shairport is run as a user service provided by the Home Manager configuration.
  boot.kernel.sysctl = {
    "net.ipv4.ip_unprivileged_port_start" = 319;
  };
  # Because this sends audio to Snapcast, the volume is generously scaled up so as not to be too quiet.
  environment.etc."shairport-sync.conf".text = ''
    general = {
      // Seems like 500ms works well here when I stream using PipeWire's RAOP module from my laptop.
      // The default for the PulseAudio backend is 350ms.
      audio_backend_buffer_desired_length_in_seconds = 0.5;
      default_airplay_volume = -12.0;
      high_threshold_airplay_volume = -8.0;
      high_volume_idle_timeout_in_minutes = 180;
      mdns_backend = "avahi";
      output_backend = "pw";
      // Use the AirPlay 2 port only.
      port = 7000;
      // Only advertise AirPlay 2.
      regtype = "_airplay._tcp";
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
  environment.etc."shairport-sync-airplay-1.conf".text = ''
    general = {
      name = "%H (AirPlay 1️⃣)";
      // Seems like 500ms works well here when I stream using PipeWire's RAOP module from my laptop.
      // When streaming from an iPhone, it seemed like I could get down to 50ms without a problem.
      // I didn't try lower.
      // The default for the PulseAudio backend is 350ms.
      audio_backend_buffer_desired_length_in_seconds = 0.5;
      default_airplay_volume = -12.0;
      high_threshold_airplay_volume = -8.0;
      high_volume_idle_timeout_in_minutes = 180;
      mdns_backend = "avahi";
      output_backend = "pw";
      volume_control_profile = "dasl_tapered";
    };
    pw = {
      application_name = "Shairport Sync AirPlay 1";
      node_name = "Shairport Sync AirPlay 1";
      sink_target = "snapserver";
    };
    sessioncontrol = {
      session_timeout = 20;
    };
    diagnostics = {
      log_verbosity = 2;
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

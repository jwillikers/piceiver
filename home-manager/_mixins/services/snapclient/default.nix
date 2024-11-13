{
  lib,
  pkgs,
  role,
  username,
  ...
}:
let
  # Omit the hostname for the Snapcast Satellite to use mDNS to discover the snapserver.
  snapcastFlags =
    [
      "--logsink system"
      # todo I'm not sure the best buffer time here, but it may need tweaked. pulse:buffer_time=100
      "--player pulse:buffer_time=75"
    ]
    ++ lib.optionals (role == "piceiver") [
      "--host ::1"
      "--soundcard Combined_Stereo_Sink"
    ]
    ++ lib.optionals (role == "snappellite") [ "--host piceiver.local" ];
  installFor = [ "core" ];
in
lib.mkIf (lib.elem username installFor) {
  systemd.user.services = {
    "snapclient" = {
      Unit = {
        Description = "Snapcast client";
        After = [
          "pipewire.service"
          "pipewire-pulse.service"
          "wireplumber.service"
          # The wireplumber-init service ensures the volume is set correctly before playback starts.
          "wireplumber-init.service"
        ];
        PartOf = [
          "pipewire-pulse.service"
        ];
        Requires = [
          "wireplumber-init.service"
        ];
        Wants = [
          "pipewire.service"
          "wireplumber.service"
        ];
      };
      Service = {
        ExecStart = "${pkgs.snapcast}/bin/snapclient " + builtins.toString snapcastFlags;
        Restart = "always";
        RestartSec = 10;
      };
      Install = {
        WantedBy = [
          "default.target"
        ];
      };
    };
  };
}

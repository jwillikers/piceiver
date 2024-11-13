{
  lib,
  osConfig,
  pkgs,
  role,
  username,
  ...
}:
let
  installFor = [ "core" ];
  script =
    if role == "piceiver" then
      "${pkgs.initialize-wireplumber}/bin/initialize-wireplumber.nu"
    else
      "${osConfig.services.pipewire.wireplumber.package}/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ 80%";
in
lib.mkIf (lib.elem username installFor) {
  systemd.user = {
    services = {
      "wireplumber-init" = {
        Unit = {
          Description = "Initialize WirePlumber default devices and volumes";
          After = [ "wireplumber.service" ];
          Requires = [ "wireplumber.service" ];
          X-Restart-Triggers = lib.optionals (role == "piceiver") [
            "${pkgs.initialize-wireplumber}/bin/initialize-wireplumber.nu"
          ];
        };
        Service = {
          # Sleep for 5 seconds to give PipeWire a chance to initialize?
          ExecStartPre = "${pkgs.coreutils}/bin/sleep 5";
          ExecStart = script;
          # RemainAfterExit = true;
          Type = "oneshot";
        };
      };
    };
    timers = {
      "wireplumber-init" = {
        Timer = {
          OnStartupSec = 10;
        };
        Install = {
          WantedBy = [ "timers.target" ];
        };
      };
    };
  };
}

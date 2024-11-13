{
  lib,
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
      # todo Keep in sync with the version in NixOs PipeWire config.
      "${pkgs.unstable.wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ 80%";
in
lib.mkIf (lib.elem username installFor) {
  systemd.user = {
    services = {
      "wireplumber-init" = {
        Unit = {
          Description = "Initialize WirePlumber default devices and volumes";
          After = [ "wireplumber.service" ];
          Requires = [ "wireplumber.service" ];
        };
        Service = {
          ExecStart = script;
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

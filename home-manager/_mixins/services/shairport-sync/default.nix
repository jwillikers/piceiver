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
in
lib.mkIf (lib.elem username installFor && role == "piceiver") {
  systemd.user.services = {
    nqptp = {
      Unit = {
        Description = "shairport-sync AirPlay 2 NQPTP server";
        Before = [ "shairport-sync.service" ];
      };
      Service = {
        ExecStart = "${pkgs.nqptp}/bin/nqptp -v";
        Restart = "always";
      };
      Install = {
        WantedBy = [ "default.target" ];
      };
    };
    shairport-sync = {
      Unit = {
        Description = "shairport-sync AirPlay server";
        After = [
          "nqptp.service"
          "pipewire.service"
          "wireplumber.service"
          # The delay from the wireplumber-init service provides enough time for all of the PipeWire nodes to become available.
          # todo I should probably use a proper `pipewire-ready.target` instead.
          "wireplumber-init.service"
        ];
        # This service needs to be restarted whenever PipeWire is.
        # If it isn't restarted, it will fallback to the combined stereo sink.
        PartOf = [
          "pipewire.service"
        ];
        Requires = [
          "nqptp.service"
          "wireplumber-init.service"
        ];
        Wants = [
          "wireplumber.service"
        ];
        X-Restart-Triggers = [
          "${osConfig.environment.etc."shairport-sync.conf".source}"
        ];
      };
      Service = {
        ExecStart = "${pkgs.shairport-sync}/bin/shairport-sync";
        Restart = "always";
        RestartSec = 10;
      };
      Install = {
        WantedBy = [ "default.target" ];
      };
    };
  };
}

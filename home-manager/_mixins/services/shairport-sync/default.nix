{
  lib,
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
        ];
        Requires = [
          "nqptp.service"
          "pipewire.service"
          "wireplumber.service"
        ];
        Wants = [ "wireplumber-init.service" ];
      };
      Service = {
        ExecStart = "${pkgs.shairport-sync}/bin/shairport-sync";
        Restart = "always";
      };
      Install = {
        WantedBy = [ "default.target" ];
      };
    };
  };
}

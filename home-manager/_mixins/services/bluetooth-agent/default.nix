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
  systemd.user.services.bluetooth-agent = {
    Unit = {
      Description = "Bluetooth Agent";
      After = [
        # bluetooth.target no go
        "wireplumber.service"
      ];
      Requires = [ "wireplumber.service" ];
    };
    Service = {
      # todo DisplayOnly or auto-off discoverability?
      ExecStartPre = "${pkgs.bluez}/bin/bluetoothctl discoverable on";
      ExecStart = "${pkgs.bluez-tools}/bin/bt-agent --capability=NoInputNoOutput";
      RestartSec = 5;
      Restart = "always";
      KillSignal = "SIGUSR1";
    };
    Install = {
      WantedBy = [ "wireplumber.service" ];
    };
  };
}

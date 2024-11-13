# Bits taken from https://github.com/nicokaiser/rpi-audio-receiver
{
  lib,
  pkgs,
  role,
  ...
}:
# let
#   bluetoothUdev = pkgs.writeShellApplication {
#     name = "bluetooth-udev";
#     text = ''
#       # From https://github.com/nicokaiser/rpi-audio-receiver
#       if [[ ! $NAME =~ ^\"([0-9A-F]{2}[:-]){5}([0-9A-F]{2})\"$ ]]; then exit 0; fi

#       # shellcheck disable=SC2153
#       action=$(expr "$ACTION" : "\([a-zA-Z]\+\).*")

#       if [ "$action" = "add" ]; then
#           ${pkgs.bluez}/bin/bluetoothctl discoverable off
#       fi

#       if [ "$action" = "remove" ]; then
#           ${pkgs.bluez}/bin/bluetoothctl discoverable on
#       fi
#     '';
#   };
# in
lib.mkIf (role == "piceiver") {
  hardware = {
    bluetooth = {
      enable = true;
      package = pkgs.unstable.bluez-experimental;
      settings = {
        General = {
          DiscoverableTimeout = 300;
          # todo Set a pairable timeout?
          # PairableTimeout = 300;
          Class = "0x200414";
          Experimental = true;
        };
      };
    };
  };
  # services.udev.extraRules = ''
  #   # From https://github.com/nicokaiser/rpi-audio-receiver
  #   SUBSYSTEM=="input", GROUP="input", MODE="0660"
  #   KERNEL=="input[0-9]*", RUN+="${bluetoothUdev}/bin/bluetooth-udev"
  # '';
  systemd.services = {
    "bluetooth-init" = {
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.bluez}/bin/bluetoothctl system-alias \"Piceiver\"";
      };
      unitConfig = {
        Description = "Set initial Bluetooth settings";
        After = [
          "bluetooth.target"
          "network-online.target"
        ];
        Requires = [
          "bluetooth.target"
          "network-online.target"
        ];
      };
      wantedBy = [ "bluetooth.target" ];
    };
    "hciconfig@" = {
      script = ''
        ${pkgs.bluez}/bin/hciconfig "$1" piscan
        ${pkgs.bluez}/bin/hciconfig "$1" sspmode 1
      '';
      scriptArgs = "%I";
      serviceConfig = {
        Type = "oneshot";
      };
      unitConfig = {
        Description = "Bluetooth Agent";
        After = [
          "bluetooth.target"
          "network-online.target"
        ];
        Requires = [
          "bluetooth.target"
          "network-online.target"
        ];
      };
      wantedBy = [ "bluetooth.target" ];
    };
    "hciconfig@hci0" = {
      overrideStrategy = "asDropin";
      wantedBy = [ "bluetooth.target" ];
    };
  };
}

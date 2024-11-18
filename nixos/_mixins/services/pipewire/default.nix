{
  lib,
  pkgs,
  raspberryPiModel,
  role,
  ...
}:
let
  raspberryPiQuantums = {
    "4" = 128; # 2.66ms latency
    "5" = 64; # 1.33ms latency
  };
  quantum = {
    min = raspberryPiQuantums.${raspberryPiModel};
    max = raspberryPiQuantums.${raspberryPiModel};
  };
in
{
  services.pipewire = {
    alsa = {
      enable = true;
      support32Bit = role == "piceiver";
    };
    enable = true;
    extraConfig = {
      pipewire."50-quantum" = {
        "context.properties" = {
          "default.clock.min-quantum" = quantum.min;
          "default.clock.max-quantum" = quantum.max;
        };
      };
      pipewire-pulse."50-low-latency" = {
        "context.properties" = [
          {
            name = "libpipewire-module-protocol-pulse";
            args = { };
          }
        ];
        "pulse.properties" = {
          "pulse.default.req" = "32/48000";
          "pulse.default.tlength" = "32/48000";
          "pulse.min.quantum" = (builtins.toString quantum.min) + "/48000";
          "pulse.min.req" = "32/48000";
        };
      };
    };
    configPackages = lib.optionals (role == "piceiver") [ pkgs.pipewire-config ];
    pulse.enable = true;
    socketActivation = false;
    wireplumber = {
      configPackages = [
        pkgs.wireplumber-optimize-usb-config
      ] ++ lib.optionals (role == "piceiver") [ pkgs.wireplumber-config ];
    };
  };
}

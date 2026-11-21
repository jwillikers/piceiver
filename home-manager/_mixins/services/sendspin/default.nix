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
  # Keep in sync with the firewall port in nixos/_mixins/services/sendspin/default.nix.
  port = 8927;
  sendspinFlags = [
    "--daemon"
    "--name ${osConfig.networking.hostName}"
    "--port ${toString port}"
  ];
in
lib.mkIf (lib.elem username installFor) {
  systemd.user.services = {
    # Sendspin player which Music Assistant discovers over mDNS and streams to.
    # Audio is played through PipeWire's PulseAudio server.
    sendspin-player = {
      Unit = {
        Description = "Sendspin player";
        After = [
          "pipewire.service"
          "pipewire-pulse.service"
          "wireplumber.service"
          # The wireplumber-init service ensures the volume is set correctly before playback starts.
          "wireplumber-init.service"
        ];
        BindsTo = [ "pipewire-pulse.service" ];
        Requires = [ "wireplumber-init.service" ];
        Wants = [
          "pipewire.service"
          "wireplumber.service"
        ];
      };
      Service = {
        Environment = [
          # miniaudio loads the audio backend libraries at runtime with dlopen.
          "LD_LIBRARY_PATH=${
            lib.makeLibraryPath [
              pkgs.alsa-lib
              pkgs.libpulseaudio
            ]
          }"
        ]
        # miniaudio uses the default PulseAudio sink when no audio device is given.
        # On the Piceiver, output to the combined sink which drives the amplifier and the subwoofer.
        ++ lib.optionals (role == "piceiver") [ "PULSE_SINK=Combined_Stereo_Sink" ];
        ExecStart = "${lib.getExe pkgs.sendspin-go} " + builtins.toString sendspinFlags;
        # The player logs every mDNS discovery of the server, which is every few seconds.
        LogFilterPatterns = "~Discovered server";
        Restart = "on-failure";
        RestartSec = 10;
      };
      Install = {
        WantedBy = [ "default.target" ];
      };
    };
  };
}

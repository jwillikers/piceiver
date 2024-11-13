{
  lib,
  role,
  username,
  ...
}:
let
  installFor = [ "core" ];
in
lib.mkIf (lib.elem username installFor && role == "piceiver") {
  services.fluidsynth = {
    enable = true;
    extraOptions = [
      "--audio-driver=pulseaudio"
      "--gain=0.4"
      "--midi-driver=alsa_seq"
      "--sample-rate=48000"
      "-o audio.driver=pulseaudio"
      "-o audio.pulseaudio.device=Combined_Stereo_Sink"
      "-o audio.realtime-prio=90"
      "-o midi.autoconnect=1"
      "-o midi.realtime-prio=90"
      "-o synth.cpu-cores=4"
    ];
    soundService = "pipewire-pulse";
  };
}

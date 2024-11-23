{
  config,
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
  home.file."${config.xdg.configHome}/rygel.conf".text = ''
    [General]
    acl-fallback-policy=true
    allow-deletion=false
    allow-upload=false
    enable-transcoding=true
    ipv6=true
    log-level=*:5
    media-engine=librygel-media-engine-gst.so
    port=1900
    strict-dlna=false

    [GstMediaEngine]
    transcoders=mp3;lpcm;mp2ts;wmv;aac;avc

    [Renderer]
    image-timeout=15

    [Tracker3]
    enabled=false

    [Tracker]
    enabled=false

    [LMS]
    enabled=false

    [MediaExport]
    enabled=false

    [External]
    enabled=false

    [org.gnome.UOnP.MediaServer2.PulseAudio]
    enabled=false

    [Playbin]
    enabled=true
    title=Audio playback on @PRETTY_HOSTNAME@
    audio-sink=pipewiresink client-name=Rygel target-object=snapserver stream-properties=\"props,application.id=rygel,application.name=Rygel,application.process.binary=rygel,application.version=${lib.getVersion pkgs.rygel},media.category=Playback,media.role=Music,media.type=Audio\"

    [GstLaunch]
    enabled=false
    launch-items=audioflacsrc
    audioflacsrc-title=FLAC on @PRETTY_HOSTNAME@
    audioflacsrc-mime=audio/flac
    audioflacsrc-launch=pipewiresrc client-name="Rygel FLAC" device=upnp.monitor ! flacenc

    [Test]
    enabled=false

    [ExampleServerPluginVala]
    enabled=false

    [ExampleServerPluginC]
    enabled=false

    [ExampleRendererPluginVala]
    enabled=false

    [ExampleRendererPluginC]
    enabled=false

    [MPRIS]
    enabled=false

    [External]
    enabled=false

    [Ruih]
    enabled=false
    title=Rygel Remote UI Server
  '';
  systemd.user.services = {
    "rygel" = {
      Unit = {
        Description = "Rygel DLNA/UPnP Digital Media Renderer";
        After = [
          "pipewire.service"
          "wireplumber.service"
          # The delay from the wireplumber-init service provides enough time for all of the PipeWire nodes to become available.
          "wireplumber-init.service"
        ];
        PartOf = [ "pipewire.service" ];
        Requires = [ "wireplumber-init.service" ];
        Wants = [ "wireplumber.service" ];
        X-Restart-Triggers = [
          "${osConfig.environment.etc."rygel.conf".source}"
          "${config.home.file."${config.xdg.configHome}/rygel.conf".source}"
        ];
      };
      Service = {
        BusName = "org.gnome.Rygel1";
        ExecStart = "${pkgs.rygel}/bin/rygel";
        Restart = "on-failure";
        RestartSec = 10;
        Type = "dbus";
      };
      Install = {
        WantedBy = [ "default.target" ];
      };
    };
  };

}

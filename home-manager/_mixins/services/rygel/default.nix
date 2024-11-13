{
  config,
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
    audio-sink=pipewiresink client-name=Rygel target-object=snapserver

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
        After = [ "wireplumber.service" ];
        Requires = [ "wireplumber.service" ];
        X-Restart-Triggers = [
          "/etc/rygel.conf"
          "${config.xdg.configHome}/rygel.conf"
        ];
      };
      Service = {
        BusName = "org.gnome.Rygel1";
        ExecStart = "${pkgs.gnome.rygel}/bin/rygel";
        Restart = "always";
        Type = "dbus";
      };
      Install = {
        WantedBy = [
          "default.target"
          "wireplumber.service"
        ];
      };
    };
  };

}

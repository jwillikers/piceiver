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
  services.mopidy = {
    enable = true;
    extensionPackages = with pkgs; [
      mopidy-iris
      mopidy-jellyfin
    ];
    # todo Make it easier to add Env=GST_DEBUG=3 to systemd unit...
    settings = {
      audio = {
        # I'm surprised I don't need a value larger than 1ms here.
        buffer_time = 1; # Must be greater than 0, default from GStreamer is 1000ms
        mixer = "software";
        mixer_volume = 50;
        # Mopidy gets all out of whack when switching between tracks using the default 44100 sample rate or possibly the S16LE format.
        # I don't know why, but updating it to 48000 seems to make everything just work.
        # Rygel uses GStreamer similarly but doesn't have problems like this, even though it uses a sample rate of 96000...
        # Maybe it's something that is a problem in the pre-release version of Mopidy.
        output = "audioconvert ! audioresample ! audio/x-raw,rate=48000,channels=2,format=S32LE ! pipewiresink client-name=Mopidy target-object=snapserver stream-properties=\"props,application.id=mopidy,application.name=Mopidy,application.process.binary=mopidy,application.version=${lib.getVersion pkgs.mopidy},media.category=Playback,media.role=Music,media.type=Audio\"";
      };
      http = {
        enabled = true;
        hostname = "::";
      };
      iris = {
        country = "us";
        locale = "en_US";
        snapcast_enabled = true;
        snapcast_host = "piceiver.local";
        snapcast_stream = "Piceiver";
      };
      jellyfin = {
        hostname = "jellyfin.lan.jwillikers.io";
        username = "jordan";
        # todo Use sops for password.
        password = "your password here";
        libraries = [
          "Books"
          "Music"
        ];
        albumartistsort = false; # (Optional: will default to True if left undefined)
        album_format = "{ProductionYear} - {Name}"; # (Optional: will default to "{Name}" if left undefined)
      };
      # logging = {
      #   verbosity = 2;
      # };
    };
  };
}

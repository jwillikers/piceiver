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
        # If you set this too low, Mopidy will get hopelessly lost when switching between tracks and become unresponsive.
        # The lowest I could get this without causing Mopidy to crash was 35ms.
        # Now lowest is 50ms for some reason...
        buffer_time = 50; # Must be greater than 0, default from GStreamer is 1000ms
        mixer = "software";
        mixer_volume = 50;
        output = "pipewiresink client-name=Mopidy target-object=snapserver stream-properties=\"props,application.id=mopidy,application.name=Mopidy,application.process.binary=mopidy,application.version=${lib.getVersion pkgs.mopidy},media.category=Playback,media.role=Music,media.type=Audio,session.suspend-timeout-seconds=0\"";
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

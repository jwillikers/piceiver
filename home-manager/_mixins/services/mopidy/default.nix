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
    settings = {
      audio = {
        # I'm surprised I don't need a value larger than 1ms here.
        buffer_time = 1; # Must be greater than 0, default from GStreamer is 1000ms
        mixer = "software";
        mixer_volume = 50;
        output = "pipewiresink client-name=Mopidy target-object=snapserver";
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
    };
  };
}

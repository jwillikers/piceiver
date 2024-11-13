{
  lib,
  pkgs,
  role,
  ...
}:
lib.mkIf (role == "piceiver") {
  # todo Make dependencies optional for graphical elements in rygel package?
  environment.etc."rygel.conf".source = "${pkgs.gnome.rygel}/etc/rygel.conf";
  networking.firewall = {
    allowedUDPPorts = [ 1900 ];
    allowedTCPPorts = [ 1900 ];
  };
  services.dbus.packages = [ pkgs.gnome.rygel ];
}

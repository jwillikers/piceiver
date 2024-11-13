{ lib, role, ... }:
lib.mkIf (role == "piceiver") {
  # The port for the Mopidy HTTP web interface.
  networking.firewall.allowedTCPPorts = [ 6680 ];
}

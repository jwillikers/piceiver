{ lib, role, ... }:
lib.mkIf (role == "piceiver") {
  # Requires an X session unfortunately
  # programs.fcast-receiver = {
  #   enable = true;
  #   openFirewall = true;
  # };
}

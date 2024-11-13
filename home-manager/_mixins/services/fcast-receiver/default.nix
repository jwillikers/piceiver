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
  # todo fcast-receiver requires an X session unfortunately
  # systemd.user.services = {
  #   "fcast-receiver" = {
  #     Unit = {
  #       Description = "FCast Receiver";
  #       After = [
  #         "pipewire-pulse.service"
  #         "wireplumber.service"
  #       ];
  #       Requires = [
  #         "pipewire-pulse.service"
  #         "wireplumber.service"
  #       ];
  #     };
  #     Service = {
  #       ExecStart = "${pkgs.fcast-receiver}/bin/fcast-receiver --no-main-window";
  #       Restart = "always";
  #     };
  #     Install = {
  #       WantedBy = [
  #         "default.target"
  #         "wireplumber.service"
  #       ];
  #     };
  #   };
  # };
}

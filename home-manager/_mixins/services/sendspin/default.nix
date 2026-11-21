{
  lib,
  osConfig,
  pkgs,
  role,
  username,
  ...
}:
let
  installFor = [ "core" ];
  # Keep in sync with the firewall port in nixos/_mixins/services/sendspin/default.nix.
  port = 8928;
  # On the Piceiver, output to the combined sink which drives the amplifier and the subwoofer.
  # Otherwise, use PipeWire's default sink.
  output = if role == "piceiver" then "pipewire:Combined_Stereo_Sink" else "pipewire";
  sendspinFlags = [
    "--name ${osConfig.networking.hostName}"
    "--output ${output}"
    "--port ${toString port}"
  ];
in
lib.mkIf (lib.elem username installFor) {
  systemd.user.services = {
    # Sendspin player which Music Assistant discovers over mDNS and streams to.
    # Connections are encrypted, and a server must pair with the player before it can play.
    # The pairing code is logged to the journal when a server starts pairing.
    sendspin-player = {
      Unit = {
        Description = "Sendspin player";
        Documentation = "https://github.com/Sendspin/sendspin-cpp-cli";
        After = [
          "pipewire.service"
          "wireplumber.service"
          # The wireplumber-init service ensures the volume is set correctly before playback starts.
          "wireplumber-init.service"
        ];
        BindsTo = [ "pipewire.service" ];
        Requires = [ "wireplumber-init.service" ];
        Wants = [ "wireplumber.service" ];
      };
      Service = {
        ExecStart = "${lib.getExe pkgs.sendspin-cli} " + builtins.toString sendspinFlags;
        Restart = "on-failure";
        RestartSec = 10;
        # Hardening from the upstream user service.
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        NoNewPrivileges = true;
        RestrictAddressFamilies = [
          "AF_UNIX"
          "AF_INET"
          "AF_INET6"
          "AF_NETLINK"
        ];
        RestrictSUIDSGID = true;
        SystemCallArchitectures = "native";
        SystemCallFilter = "@system-service";
      };
      Install = {
        WantedBy = [ "default.target" ];
      };
    };
  };
}

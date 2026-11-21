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
  # With secrets, the player's identity and pairing records are stored in the nix-secrets repository.
  # Restore them when they're missing, i.e. on a new SD card, so that Music Assistant doesn't have to pair again.
  # The player writes to this file, so it's copied instead of linked.
  stateSecret = osConfig.sops.secrets."sendspin-cli/state".path or null;
  restoreState = pkgs.writeShellScript "restore-sendspin-state" ''
    if [ ! -e "$1" ]; then
      ${lib.getExe' pkgs.coreutils "install"} -D --mode=600 "$2" "$1"
    fi
  '';
in
lib.mkIf (lib.elem username installFor) {
  # Make the player's subcommands available, i.e. sendspin-cli status.
  home.packages = [ pkgs.sendspin-cli ];
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
        ExecStartPre = lib.optional (
          stateSecret != null
        ) "${restoreState} %S/sendspin-cli/state ${stateSecret}";
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

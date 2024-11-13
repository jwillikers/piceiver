_: {
  # todo Enable support for Bcachefs once the kernel is updated to at least 6.7.
  # # Create a bootable ISO image with bcachefs.
  # # - https://wiki.nixos.org/wiki/Bcachefs
  # boot = {
  #   supportedFilesystems = [ "bcachefs" ];
  # };
  # environment.systemPackages = with pkgs; [
  #   bcachefs-tools
  #   keyutils
  # ];
}

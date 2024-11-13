{
  lib,
  pkgs,
  username,
  ...
}:
{
  imports = [
    ./core
    ./root
  ] ++ lib.optional (builtins.pathExists (./. + "/${username}")) ./${username};
  environment.localBinInPath = true;
  users = {
    users.${username} = {
      extraGroups = [
        "audio"
        "dialout"
        "input"
        "networkmanager"
        "users"
        "video"
        "wheel"
      ];
      isNormalUser = true;
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAP56w70Wms1Dez5p7eGGgF0rmJd87VLX5CaVrDIRYaa jordan@precision5350.jwillikers.io"
      ];
      packages = [ pkgs.home-manager ];
      shell = pkgs.fish;
    };
    # Only set usable users for customized image.
    mutableUsers = false;
  };
}

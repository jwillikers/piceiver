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
  ]
  ++ lib.optional (builtins.pathExists (./. + "/${username}")) ./${username};
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
      packages = [ pkgs.home-manager ];
      shell = pkgs.fish;
    };
    # Only set usable users for customized image.
    mutableUsers = false;
  };
}

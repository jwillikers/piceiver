{
  inputs,
  stateVersion,
  username,
  ...
}:
{
  imports = [
    inputs.nix-index-database.hmModules.nix-index
    ./_mixins/services
    ./_mixins/users
  ];

  home = {
    inherit stateVersion;
    inherit username;
    homeDirectory = "/home/${username}";
  };

  # Workaround home-manager bug with flakes
  # - https://github.com/nix-community/home-manager/issues/2033
  news.display = "silent";

  nix = {
    settings = {
      experimental-features = "flakes nix-command";
      trusted-users = [
        "root"
        "jordan"
      ];
    };
  };

  programs.home-manager.enable = true;

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";
  # Create age keys directory for SOPS
  # systemd.user.tmpfiles = {
  #   rules = [ "d ${config.xdg.configHome}/sops/age 0750 ${username} ${username} - -" ];
  # };
}

_: {
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      if ! set --query XDG_RUNTIME_DIR
        set --export --universal XDG_RUNTIME_DIR /run/user/(id --user)
      end
    '';
  };
}

pkgs: {
  initialize-wireplumber = pkgs.callPackage ./initialize-wireplumber/package.nix { };
  pipewire-config = pkgs.callPackage ./pipewire-config/package.nix { };
  wireplumber-config = pkgs.callPackage ./wireplumber-config/package.nix { };
  wireplumber-optimize-usb-config = pkgs.callPackage ./wireplumber-config/package.nix { };
}

{
  lib,
  makeWrapper,
  nushell,
  pipewire,
  stdenvNoCC,
  wireplumber,
}:
stdenvNoCC.mkDerivation {
  pname = "initialize-wireplumber";
  version = "0";

  nativeBuildInputs = [ makeWrapper ];

  # todo Is this necessary?
  buildInputs = [ nushell ];

  src = ./.;

  installPhase = ''
    runHook preInstall
    install -D --mode=0755 --target-directory=$out/bin initialize-wireplumber.nu
    wrapProgram "$out/bin/initialize-wireplumber.nu" \
      --set PATH ${
        lib.makeBinPath [
          pipewire
          wireplumber
        ]
      }
    runHook postInstall
  '';

  meta.mainProgram = "initialize-wireplumber.nu";
}

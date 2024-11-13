{ stdenvNoCC }:
stdenvNoCC.mkDerivation {
  pname = "pipewire-config";
  version = "0";

  src = ./.;

  installPhase = ''
    runHook preInstall
    install -D --mode=0644 --target-directory=$out/share/pipewire/pipewire.conf.d pipewire.conf.d/*.conf
    runHook postInstall
  '';
}

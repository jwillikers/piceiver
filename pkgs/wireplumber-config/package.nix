{ stdenvNoCC }:
stdenvNoCC.mkDerivation {
  pname = "wireplumber-config";
  version = "0";

  src = ./.;

  installPhase = ''
    runHook preInstall
    install -D --mode=0644 --target-directory=$out/share/wireplumber/wireplumber.conf.d wireplumber.conf.d/*.conf
    runHook postInstall
  '';
}

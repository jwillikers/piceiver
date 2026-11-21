{
  alsa-lib,
  avahi-compat,
  cmake,
  fetchgit,
  lib,
  libpulseaudio,
  ninja,
  pipewire,
  pkg-config,
  stdenv,
}:
let
  # The source and the dependencies which the CMake build would otherwise download with FetchContent.
  # Update them with update.nu, i.e. nix run .#update-packages.
  sources = lib.importJSON ./sources.json;
  fetchSource =
    source:
    fetchgit {
      inherit (source)
        url
        rev
        hash
        fetchSubmodules
        ;
    };
in
stdenv.mkDerivation {
  pname = "sendspin-cli";
  inherit (sources) version;

  src = fetchSource sources.src;

  nativeBuildInputs = [
    cmake
    ninja
    pkg-config
  ];

  buildInputs = [
    alsa-lib
    avahi-compat
    libpulseaudio
    pipewire
  ];

  cmakeFlags = [
    (lib.cmakeBool "FETCHCONTENT_FULLY_DISCONNECTED" true)
    # The interactive terminal UI isn't needed for a headless player.
    (lib.cmakeBool "SENDSPIN_CLI_WITH_TUI" false)
    (lib.cmakeBool "SENDSPIN_CLI_BUILD_TESTS" false)
    (lib.cmakeBool "SENDSPIN_USE_CCACHE" false)
  ];

  # Fail early if sources.json is out of sync with the tags pinned upstream.
  postPatch = ''
    grep --quiet --fixed-strings 'set(SENDSPIN_GIT_TAG "${sources.dependencies.SENDSPIN.tag}"' CMakeLists.txt || {
      echo "sources.json doesn't match the sendspin-cpp tag in CMakeLists.txt. Run update.nu." >&2
      exit 1
    }
  '';

  # Some dependencies write into their source directories while configuring,
  # so copy them out of the read-only Nix store first.
  # The dependencies are keyed by the uppercase FetchContent name.
  preConfigure = ''
    mkdir -p "$NIX_BUILD_TOP/deps"
  ''
  + lib.concatStrings (
    lib.mapAttrsToList (name: source: ''
      cp -r --no-preserve=mode ${fetchSource source} "$NIX_BUILD_TOP/deps/${name}"
      appendToVar cmakeFlags "-DFETCHCONTENT_SOURCE_DIR_${name}=$NIX_BUILD_TOP/deps/${name}"
    '') sources.dependencies
  )
  + lib.concatStrings (
    lib.mapAttrsToList (name: source: ''
      grep --quiet --extended-regexp 'GIT_TAG +${lib.escapeRegex source.tag}$' "$NIX_BUILD_TOP/deps/SENDSPIN/cmake/host.cmake" || {
        echo "sources.json doesn't match the ${name} tag in sendspin-cpp's cmake/host.cmake. Run update.nu." >&2
        exit 1
      }
    '') (removeAttrs sources.dependencies [ "SENDSPIN" ])
  );

  passthru.updateScript = ./update.nu;

  meta = {
    description = "Sendspin synchronized audio player for Linux";
    homepage = "https://github.com/Sendspin/sendspin-cpp-cli";
    license = lib.licenses.asl20;
    mainProgram = "sendspin-cli";
    platforms = lib.platforms.linux;
  };
}

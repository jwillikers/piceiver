{ inputs, ... }:
{
  # Add custom packages from the pkgs directory
  additions = final: _prev: import ../pkgs final.pkgs;

  ccache = _final: prev: {
    ccacheWrapper = prev.ccacheWrapper.override {
      extraConfig = ''
        # Increase the maximum size of the cache.
        export CCACHE_MAXSIZE=75Gi

        # This path must be configured fox Nix and NixOS as an extra sandbox path.
        export CCACHE_DIR="/nix/var/cache/ccache"
        export CCACHE_UMASK=007
        if [ ! -d "$CCACHE_DIR" ]; then
          echo "====="
          echo "Directory '$CCACHE_DIR' does not exist"
          echo "Please create it with:"
          echo "  sudo mkdir --mode=0770 --parents '$CCACHE_DIR'"
          echo "  sudo chown root:nixbld '$CCACHE_DIR'"
          echo "====="
          exit 1
        fi
        if [ ! -w "$CCACHE_DIR" ]; then
          echo "====="
          echo "Directory '$CCACHE_DIR' is not accessible for user $(whoami)"
          echo "Please verify its access permissions"
          echo "====="
          exit 1
        fi
      '';
    };
  };

  # Disable unnecessary graphics support.
  modifications = final: prev: {
    dbus = prev.dbus.override { x11Support = false; };
    ffmpeg = prev.ffmpeg.override {
      ffmpegVariant = "headless";
    };
    # Disable GTK support and add PipeWire GStreamer plugin.
    rygel = prev.rygel.overrideAttrs (prevAttrs: {
      nativeBuildInputs = (prev.lib.lists.remove prev.wrapGAppsHook3 prevAttrs.nativeBuildInputs) ++ [
        prev.wrapGAppsNoGuiHook
      ];
      buildInputs = (prev.lib.lists.remove final.gtk3 prevAttrs.buildInputs) ++ [
        prev.pipewire
        prev.gdk-pixbuf
      ];
      mesonFlags = prevAttrs.mesonFlags ++ [
        "-Dgtk=disabled"
        "-Dx11=disabled"
      ];
      patches = prevAttrs.patches or [ ] ++ [
        (prev.fetchpatch2 {
          url = "https://gitlab.gnome.org/jwillikers/rygel/-/commit/8c7052ac7d61f190adeb1ef4251e6c7c77993872.patch";
          hash = "sha256-dfsZ0FKYBW8KzpPk/5WfX454BOscCXVkkPBuftVCRoQ=";
        })
      ];
    });
    # todo Make it possible to disable graphviz support in libcamera.
    graphviz = prev.graphviz.override { withXorg = false; };
    gst_all_1 = prev.gst_all_1 // {
      # gstreamer = prev.gst_all_1.gstreamer.overrideAttrs (prevAttrs: rec {
      #   version = "1.24.9";
      #   src = prev.fetchurl {
      #     url = "https://gstreamer.freedesktop.org/src/${prevAttrs.pname}/${prevAttrs.pname}-${version}.tar.xz";
      #     hash = "sha256-6/R7a+71CKAMhVfUwfFxPlx++bpw2sRd7tgOGCvPJg8=";
      #   };
      # });
      # gst-plugins-bad = prev.gst_all_1.gst-plugins-bad.overrideAttrs (prevAttrs: rec {
      #   version = "1.24.9";
      #   src = prev.fetchurl {
      #     url = "https://gstreamer.freedesktop.org/src/${prevAttrs.pname}/${prevAttrs.pname}-${version}.tar.xz";
      #     hash = "sha256-Nvz3qa8KdTtDuwO5g1JG901y9xJDaeZqHi3HsE9aXKs=";
      #   };
      # });
      gst-plugins-base = prev.gst_all_1.gst-plugins-base.override {
        enableX11 = false;
        enableWayland = false;
      };
      # }).overrideAttrs
      #   (prevAttrs: rec {
      #     # version = "1.24.9";
      #     # src = prev.fetchurl {
      #     #   url = "https://gstreamer.freedesktop.org/src/${prevAttrs.pname}/${prevAttrs.pname}-${version}.tar.xz";
      #     #   hash = "sha256-W7O5RpB9POBN2EK2EMgRHCsGETUbJaH6Iq9e+ol4V8s=";
      #     # };
      #   });
      gst-plugins-good = prev.gst_all_1.gst-plugins-good.override {
        enableX11 = false;
        enableWayland = false;
      };
      # }).overrideAttrs
      #   (prevAttrs: rec {
      #     version = "1.24.9";
      #     src = prev.fetchurl {
      #       url = "https://gstreamer.freedesktop.org/src/${prevAttrs.pname}/${prevAttrs.pname}-${version}.tar.xz";
      #       hash = "sha256-iX3lC/8zfjyi+G8eqijggo2DAkFWFipQxOoK+G4peZ8=";
      #     };
      #   });
      # gst-libva = prev.gst_all_1.gst-libva.overrideAttrs (prevAttrs: rec {
      #   version = "1.24.9";
      #   src = prev.fetchurl {
      #     url = "https://gstreamer.freedesktop.org/src/${prevAttrs.pname}/${prevAttrs.pname}-${version}.tar.xz";
      #     hash = "sha256-MmgumuUI7gH0+xNLOlIAgeKsAHIgmXV3YksdFhcdRWw=";
      #   };
      # });
      gst-plugins-rs = prev.gst_all_1.gst-plugins-rs.override {
        withGtkPlugins = false;
      };
      # gst-plugins-ugly = prev.gst_all_1.gst-plugins-ugly.overrideAttrs (prevAttrs: rec {
      #   version = "1.24.9";
      #   src = prev.fetchurl {
      #     url = "https://gstreamer.freedesktop.org/src/${prevAttrs.pname}/${prevAttrs.pname}-${version}.tar.xz";
      #     hash = "sha256-S2swEQ84zQXrZ0IilxQrdaVf4AADEF9IsTYD5nYcw7Y=";
      #   };
      # });
    };
    gtk3 = prev.gtk3.override {
      broadwaySupport = false;
      cupsSupport = false;
      trackerSupport = false;
      # todo Why does it break the build when I disable X11 support?
      # x11Support = false;
      xineramaSupport = false;
      # waylandSupport = false;
      # }).overrideAttrs (prevAttrs: {
      # mesonFlags = prevAttrs.mesonFlags ++ [ "-Dwayland_backend=false" ];
    };
    gtk4 = prev.gtk4.override {
      broadwaySupport = false;
      cupsSupport = false;
      trackerSupport = false;
      # x11Support = false;
      # todo Fix xinerama support is required when x11Support is enabled.
      # xineramaSupport = false;
      vulkanSupport = false;
      # waylandSupport = false;
      # }).overrideAttrs (prevAttrs: {
      # mesonFlags = prevAttrs.mesonFlags ++ [ "-Dwayland-backend=false" ];
    };
    # libepoxy = prev.libepoxy.override {
    #   x11Support = false;
    # };
    matio = prev.matio.overrideAttrs (_prevAttrs: {
      configureFlags = [
        "ac_cv_va_copy=1"
      ];
    });
    # todo Fix this so that it actually gets used as part of the service...
    mopidyPackages = prev.mopidyPackages // {
      # Use a newer version and add PipeWire GStreamer plugin.
      mopidy = prev.python3Packages.buildPythonApplication rec {
        pname = "mopidy";
        pyproject = true;
        version = "4.0.0a1";

        src = prev.fetchFromGitHub {
          owner = "mopidy";
          repo = "mopidy";
          rev = "refs/tags/v${version}";
          hash = "sha256-+YjiAysDVfuEpohcWMU5he8yp1tr/g4aLxqrKuhrjWY=";
        };

        patches = [
          ./0001-Use-playbin3.patch
          ./0002-Use-decodebin3.patch
        ];

        build-system = with prev.python3Packages; [
          setuptools
          setuptools-scm
        ];

        nativeBuildInputs = [ prev.wrapGAppsNoGuiHook ];

        propagatedNativeBuildInputs = [
          prev.gobject-introspection
        ];

        propagatedBuildInputs = [
          prev.gobject-introspection
        ];

        buildInputs =
          with final.gst_all_1;
          [
            gst-plugins-bad
            gst-plugins-base
            gst-plugins-good
            gst-plugins-ugly
            gst-plugins-rs
          ]
          ++ [
            prev.glib-networking
            prev.pipewire
          ];

        dependencies = with prev.python3Packages; [
          gst-python
          pygobject3
          pykka
          requests
          setuptools
          tornado
        ];

        # There are no tests
        doCheck = false;

        meta = {
          homepage = "https://www.mopidy.com/";
          description = "Extensible music server that plays music from local disk, Spotify, SoundCloud, and more";
          mainProgram = "mopidy";
          license = with prev.lib.licenses; [ asl20 ];
          maintainers = with prev.lib.maintainers; [ fpletz ];
          hydraPlatforms = [ ];
        };
      };
    };
    nushell = prev.nushell.override {
      withDefaultFeatures = false;
    };
    openslide = prev.openslide.overrideAttrs (_prevAttrs: {
      depsBuildBuild = [ prev.buildPackages.stdenv.cc ];
    });
    pipewire = prev.pipewire.override {
      # todo Add support for disabling x11Support in vulkan-loader package.
      vulkanSupport = false;
      x11Support = false;
    };
    poppler = prev.poppler.overrideAttrs (prevAttrs: {
      nativeBuildInputs = prevAttrs.nativeBuildInputs ++ [ prev.glib ];
    });
    # NODE_OPTIONS = "--openssl-legacy-provider";
    # nodePackages.sharp = prev.nodePackages.sharp.override (oldAttrs:{
    # nativeBuildInputs = [
    #   prev.pkg-config
    # ];
    # buildInputs = with prev; [
    #   # required by sharp
    #   # https://sharp.pixelplumbing.com/install
    #   vips
    #   final.node-gyp-build
    #   node-pre-gyp
    # ];

    snapweb = prev.snapweb.overrideAttrs (
      prevAttrs:
      let
        node-addon-api = prev.stdenvNoCC.mkDerivation rec {
          pname = "node-addon-api";
          version = "8.0.0";
          src = prev.fetchFromGitHub {
            owner = "nodejs";
            repo = "node-addon-api";
            rev = "v${version}";
            hash = "sha256-k3v8lK7uaEJvcaj1sucTjFZ6+i5A6w/0Uj9rYlPhjCE=";
          };
          installPhase = ''
            mkdir $out
            cp -r *.c *.h *.gyp *.gypi index.js package-support.json package.json tools $out/
          '';
        };
      in
      {
        makeCacheWritable = true; # sharp tries to build stuff in node_modules
        nativeBuildInputs = prevAttrs.nativeBuildInputs ++ [
          prev.node-gyp
          node-addon-api
          prev.python3
        ];
        env.SHARP_FORCE_GLOBAL_LIBVIPS = "true";
        # preBuild = ''
        #   pushd node_modules/sharp

        #   mkdir node_modules
        #   ln -s ${node-addon-api} node_modules/node-addon-api

        #   ${prev.lib.getExe prev.nodejs} install/check

        #   rm -r node_modules

        #   popd
        #   rm -r node_modules/@img/sharp*
        # '';
        # pkgConfig.sharp = {
        #   nativeBuildInputs = [
        #     prev.pkg-config
        #     prev.python3
        #     prev.node-gyp
        #     prev.nodePackages.semver
        #   ];
        #   buildInputs = [ prev.vips ];
        #   postInstall = ''
        #     yarn --offline run install
        #   '';
        # };
        # nativeBuildInputs = prevAttrs.nativeBuildInputs ++ [prev.node-gyp];
        # buildInputs = prevAttrs.buildInputs ++ [prev.nodePackages.sharp];
        # # add newer node-addon-api to build sharp
        # # https://github.com/lovell/sharp/issues/3920
        # dependencies = [
        #   {
        #     name = "node-addon-api";
        #     packageName = "node-addon-api";
        #     version = "7.1.0";
        #     src = prev.fetchurl {
        #       url = "https://registry.npmjs.org/node-addon-api/-/node-addon-api-7.1.0.tgz";
        #       sha512 = "mNcltoe1R8o7STTegSOHdnJNN7s5EUvhoS7ShnTHDyOSd+8H+UdWODq6qSv67PjC8Zc5JRT8+oLAMCr0SIXw7g==";
        #     };
        #   }
        # ];
      }
    );
    # Not sure how to entirely disable openconnect which is pulled in by NetworkManager.
    # So instead, just disable the GTK dependency that it indirectly pulls in.
    stoken = prev.stoken.override { withGTK3 = false; };
    libxkbcommon = prev.libxkbcommon.overrideAttrs (prevAttrs: {
      nativeBuildInputs = prev.lib.lists.remove prev.xorg.xorgserver prevAttrs.nativeBuildInputs;
      buildInputs = prev.lib.lists.remove prev.xorg.libxcb prevAttrs.buildInputs;
      mesonFlags = prevAttrs.mesonFlags ++ [ "-Denable-x11=false" ];
    });
    # vips = prev.vips.overrideAttrs(prevAttrs: {
    # nativeBuildInputs = prevAttrs.nativeBuildInputs ++ [ prev.cmake ];
    # buildInputs = prev.lib.lists.remove prev.poppler (prev.lib.lists.remove prev.openslide (prev.lib.lists.remove prev.matio prevAttrs.buildInputs));
    # mesonFlags = prevAttrs.mesonFlags ++ [ "-Dmatio=disabled" "-Dopenslide=disabled" "-Dpoppler=disabled" ];
    # });
  };

  # https://github.com/NixOS/nixpkgs/issues/154163
  allow-missing-modules = _final: prev: {
    makeModulesClosure = x: prev.makeModulesClosure (x // { allowMissing = true; });
  };

  # Makes the unstable nixpkgs set accessible through 'pkgs.unstable'
  unstablePackages = final: _prev: {
    unstable = import inputs.nixpkgs-unstable { inherit (final) system; };
  };

  # Use a newer version of shairport-sync to get the latest bug fixes.
  # We need fixes for ffmpeg 7 which as-of-yet are unreleased.
  unstable-shairport-sync = _final: prev: {
    shairport-sync = prev.shairport-sync.overrideAttrs (_prevAttrs: {
      version = "4.3.5-dev";
      src = prev.fetchFromGitHub {
        repo = "shairport-sync";
        owner = "mikebrady";
        rev = "ab6225c1ac1c57f5af50890d722437ec8a921d0d";
        hash = "sha256-iwyIUUFA5DzTkm/DXvEa3buVX4Dje0P0svteRAKIS20=";
      };
    });
  };

  # Add a separate package for shairport-sync with AirPlay 2 support enabled.
  shairport-sync-airplay2 = _final: prev: {
    shairport-sync-airplay2 = prev.shairport-sync.override { enableAirplay2 = true; };
  };

  realtime =
    _final: prev:
    let
      autoModules = false;
      v6_6_54 = {
        rt-patch = {
          name = "rt";
          patch = prev.fetchurl {
            url = "mirror://kernel/linux/kernel/projects/rt/6.6/older/patch-6.6.53-rt44.patch.xz";
            sha256 = "sha256-LydfWRvOAMby42eDo0arQdpPXuA6v7SWIyDh/eHa07s=";
          };
        };
        modDirVersion = "6.6.54-rt44";
      };
      v6_10_12 = {
        rt-patch = {
          name = "rt";
          patch = prev.fetchurl {
            url = "mirror://kernel/linux/kernel/projects/rt/6.10/older/patch-6.10.2-rt14.patch.xz";
            sha256 = "sha256-qQ6mXEvk/VQykA322EgG6fWkuaKHTwY/nfZx216N8Jo=";
          };
        };
        modDirVersion = "6.10.12-rt14";
      };
      stdenv = prev.ccacheStdenv;
      structuredExtraConfig = with prev.lib.kernel; {
        # Audio
        # Enable HDA soundcard support for the PCIe soundcard.
        # This isn't enabled by default in the Raspberry Pi kernel config.
        SND_HDA_GENERIC = yes;
        SND_HDA_INTEL = module;
        SND_BCM2708_SOC_IQAUDIO_DAC = module;
        SND_BCM2708_SOC_IQAUDIO_DIGI = module;
        SND_BCM2708_SOC_RPI_DAC = module;
        SND_DESIGNWARE_I2S = module;
        SND_DESIGNWARE_PCM = yes;

        # realtime
        # PREEMPT_RT was merged in to kernel 6.12.
        # https://github.com/NixOS/nixpkgs/blob/master/pkgs/os-specific/linux/kernel/linux-rt-6.1.nix
        PREEMPT_RT = yes;
        EXPERT = yes; # PREEMPT_RT depends on it (in kernel/Kconfig.preempt)
        # Fix error: option not set correctly: PREEMPT_VOLUNTARY (wanted 'y', got 'n').
        PREEMPT_VOLUNTARY = prev.lib.mkForce no; # PREEMPT_RT deselects it.
        # Fix error: unused option: RT_GROUP_SCHED.
        RT_GROUP_SCHED = prev.lib.mkForce (option no); # Removed by sched-disable-rt-group-sched-on-rt.patch.

        # Prune unnecessary drivers to reduce the build time.

        ## Filesystems
        CEPH_FS = no;
        CIFS = no;
        EXFAT_FS = no;
        GFS2_FS = no;
        HFS_FS = no;
        HFSPLUS_FS = no;
        JFS_FS = no;
        JFFS2_FS = no;
        NFS_FS = no;
        NFSD = no;
        NILFS2_FS = no;
        NTFS_FS = no;
        NTFS3_FS = no;
        OCFS2_FS = no;
        REISERFS_FS = no;
        SMB_SERVER = no;
        SQUASHFS = no;
        UBIFS_FS = no;
        XFS_FS = no;

        ## Framebuffer
        FB_SSD1307 = no;
        FB_TFT = no;

        ## HID
        HID_A4TECH = no;
        HID_ACRUX = no;
        HID_APPLE = no;
        HID_ASUS = no;
        HID_BIGBEN_FF = no;
        HID_CHERRY = no;
        HID_CHICONY = no;
        HID_CYPRESS = no;
        HID_DRAGONRISE = no;
        HID_EMS_FF = no;
        HID_ELECOM = no;
        HID_ELO = no;
        HID_EZKEY = no;
        HID_GEMBIRD = no;
        HID_HOLTEK = no;
        HID_KEYTOUCH = no;
        HID_KYE = no;
        HID_UCLOGIC = no;
        HID_WALTOP = no;
        HID_GYRATION = no;
        HID_TWINHAN = no;
        HID_KENSINGTON = no;
        HID_LCPOWER = no;
        HID_MONTEREY = no;
        HID_NINTENDO = no;
        HID_NTRIG = no;
        HID_ORTEK = no;
        HID_PANTHERLORD = no;
        HID_PETALYNX = no;
        HID_PICOLCD = no;
        HID_ROCCAT = no;
        HID_SONY = no;
        HID_SPEEDLINK = no;
        HID_STEAM = no;
        HID_SUNPLUS = no;
        HID_GREENASIA = no;
        HID_SMARTJOYPLUS = no;
        HID_TOPSEED = no;
        HID_THINGM = no;
        HID_THRUSTMASTER = no;
        HID_WIIMOTE = no;
        HID_XINMO = no;
        HID_ZEROPLUS = no;
        HID_ZYDACRON = no;

        ## Industrial IO
        BME680 = no;
        CCS811 = no;
        SENSIRION_SGP30 = no;
        SPS30_I2C = no;
        DHT11 = no;
        HDC100X = no;
        HTU21 = no;
        SI7020 = no;
        BOSCH_BNO055_I2C = no;
        INV_MPU6050_I2C = no;
        APDS9960 = no;
        BH1750 = no;
        TSL4531 = no;
        VEML6070 = no;
        BMP280 = no;
        MS5637 = no;
        MAXIM_THERMOCOUPLE = no;
        MAX31856 = no;

        ## Input
        INPUT_JOYSTICK = no;
        INPUT_TOUCHSCREEN = no;
        INPUT_AD714X = no;
        INPUT_ATI_REMOTE2 = no;
        INPUT_KEYSPAN_REMOTE = no;
        INPUT_POWERMATE = no;
        INPUT_YEALINK = no;
        INPUT_CM109 = no;
        INPUT_ADXL34X = no;
        INPUT_CMA3000 = no;

        ## Microsoft Surface
        SURFACE_PLATFORMS = no;

        ## Multifunction
        MFD_RASPBERRYPI_POE_HAT = no;
        MFD_STMPE = no;

        ## Networking
        CAN = no;

        ## PWM
        PWM_PCA9685 = no;

        ## RTC
        RTC_DRV_ABX80X = no;
        RTC_DRV_DS1307 = no;
        RTC_DRV_DS1374 = no;
        RTC_DRV_DS1672 = no;
        RTC_DRV_MAX6900 = no;
        RTC_DRV_RS5C372 = no;
        RTC_DRV_ISL1208 = no;
        RTC_DRV_ISL12022 = no;
        RTC_DRV_X1205 = no;
        RTC_DRV_PCF8523 = no;
        RTC_DRV_PCF85063 = no;
        RTC_DRV_PCF85363 = no;
        RTC_DRV_PCF8563 = no;
        RTC_DRV_PCF8583 = no;
        RTC_DRV_M41T80 = no;
        RTC_DRV_BQ32K = no;
        RTC_DRV_S35390A = no;
        RTC_DRV_FM3130 = no;
        RTC_DRV_RX8581 = no;
        RTC_DRV_RX8025 = no;
        RTC_DRV_EM3027 = no;
        RTC_DRV_RV3028 = no;
        RTC_DRV_RV3032 = no;
        RTC_DRV_RV8803 = no;
        RTC_DRV_SD3078 = no;
        RTC_DRV_M41T93 = no;
        RTC_DRV_M41T94 = no;
        RTC_DRV_DS1302 = no;
        RTC_DRV_DS1305 = no;
        RTC_DRV_DS1390 = no;
        RTC_DRV_R9701 = no;
        RTC_DRV_RX4581 = no;
        RTC_DRV_RS5C348 = no;
        RTC_DRV_MAX6902 = no;
        RTC_DRV_PCF2123 = no;
        RTC_DRV_DS3232 = no;
        RTC_DRV_PCF2127 = no;
        RTC_DRV_RV3029C2 = no;

        ## SOC Soundcards
        SND_BCM2708_SOC_CHIPDIP_DAC = no;
        SND_BCM2708_SOC_GOOGLEVOICEHAT_SOUNDCARD = no;
        SND_BCM2708_SOC_HIFIBERRY_DAC = no;
        SND_BCM2708_SOC_HIFIBERRY_DACPLUS = no;
        SND_BCM2708_SOC_HIFIBERRY_DACPLUSHD = no;
        SND_BCM2708_SOC_HIFIBERRY_DACPLUSADC = no;
        SND_BCM2708_SOC_HIFIBERRY_DACPLUSADCPRO = no;
        SND_BCM2708_SOC_HIFIBERRY_DACPLUSDSP = no;
        SND_BCM2708_SOC_HIFIBERRY_DIGI = no;
        SND_BCM2708_SOC_HIFIBERRY_AMP = no;
        SND_BCM2708_SOC_PIFI_40 = no;
        SND_BCM2708_SOC_RPI_CIRRUS = no;
        SND_BCM2708_SOC_RPI_PROTO = no;
        SND_BCM2708_SOC_JUSTBOOM_BOTH = no;
        SND_BCM2708_SOC_JUSTBOOM_DAC = no;
        SND_BCM2708_SOC_JUSTBOOM_DIGI = no;
        SND_BCM2708_SOC_IQAUDIO_CODEC = no;
        SND_BCM2708_SOC_I_SABRE_Q2M = no;
        SND_BCM2708_SOC_ADAU1977_ADC = no;
        SND_AUDIOINJECTOR_PI_SOUNDCARD = no;
        SND_AUDIOINJECTOR_OCTO_SOUNDCARD = no;
        SND_AUDIOINJECTOR_ISOLATED_SOUNDCARD = no;
        SND_AUDIOSENSE_PI = no;
        SND_DIGIDAC1_SOUNDCARD = no;
        SND_BCM2708_SOC_DIONAUDIO_LOCO = no;
        SND_BCM2708_SOC_DIONAUDIO_LOCO_V2 = no;
        SND_BCM2708_SOC_ALLO_PIANO_DAC = no;
        SND_BCM2708_SOC_ALLO_PIANO_DAC_PLUS = no;
        SND_BCM2708_SOC_ALLO_BOSS_DAC = no;
        SND_BCM2708_SOC_ALLO_BOSS2_DAC = no;
        SND_BCM2708_SOC_ALLO_DIGIONE = no;
        SND_BCM2708_SOC_ALLO_KATANA_DAC = no;
        SND_BCM2708_SOC_FE_PI_AUDIO = no;
        SND_PISOUND = no;
        SND_RPI_SIMPLE_SOUNDCARD = no;
        SND_RPI_WM8804_SOUNDCARD = no;
        SND_DACBERRY400 = no;

        ## Touchscreens
        DRM_PANEL_RASPBERRYPI_TOUCHSCREEN = no;
        DRM_PANEL_WAVESHARE_TOUCHSCREEN = no;

        ## USB
        USB_PRINTER = no;
        USB_MICROTEK = no;
        USB_MDC800 = no;
        PRISM2_USB = no;
        USB_ACM = no;
        USB_ATM = no;
        USB_YUREX = no;
        USB_ISIGHTFW = no;
        USB_IOWARRIOR = no;
        USB_TRANCEVIBRATOR = no;
        USB_LD = no;
        USB_APPLEDISPLAY = no;
        USB_IDMOUSE = no;
        USB_ADUTUX = no;
        USB_LEGOTOWER = no;
        USB_CYPRESS_CY7C63 = no;
        USB_CYTHERM = no;
        USB_VL600 = no;

        ## VHOST
        VHOST_NET = no;
        VHOST_VSOCK = no;

        ## Disable extra options turned on by the NixOS kernel configuration

        ### Filesystems
        F2FS_FS = prev.lib.mkForce no;

        ### Infiniband
        INFINIBAND = prev.lib.mkForce no;

        ### Misc
        CHROME_PLATFORMS = prev.lib.mkForce no;
        TCG_TIS_SPI_CR50 = prev.lib.mkForce no;
      };
    in
    {
      rpi-kernels.v6_6_54.bcm2711 = prev.rpi-kernels.v6_6_54.bcm2711.override (prevKernel: {
        inherit autoModules stdenv;
        inherit (v6_6_54) modDirVersion;
        kernelPatches = [ v6_6_54.rt-patch ] ++ prevKernel.kernelPatches;
        structuredExtraConfig = structuredExtraConfig // prevKernel.structuredExtraConfig;
      });
      rpi-kernels.v6_6_54.bcm2712 = prev.rpi-kernels.v6_6_54.bcm2712.override (prevKernel: {
        inherit autoModules stdenv;
        inherit (v6_6_54) modDirVersion;
        kernelPatches = [ v6_6_54.rt-patch ] ++ prevKernel.kernelPatches;
        structuredExtraConfig = structuredExtraConfig // prevKernel.structuredExtraConfig;
      });
      # The realtime patchset fails to apply on kernel 6.10.12.
      # I will probably just wait for 6.12.
      rpi-kernels.v6_10_12.bcm2712 = prev.rpi-kernels.v6_10_12.bcm2712.override (prevKernel: {
        inherit autoModules stdenv;
        inherit (v6_10_12) modDirVersion;
        structuredExtraConfig = structuredExtraConfig // prevKernel.structuredExtraConfig;
        kernelPatches = [ v6_10_12.rt-patch ] ++ prevKernel.kernelPatches;
      });
    };
}

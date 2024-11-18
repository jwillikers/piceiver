{ inputs, ... }:
{
  # Add custom packages from the pkgs directory
  additions = final: _prev: import ../pkgs final.pkgs;

  # Disable unnecessary graphics support.
  modifications = final: prev: {
    dbus = prev.dbus.override { x11Support = false; };
    ffmpeg = prev.ffmpeg.override {
      ffmpegVariant = "headless";
    };
    gnome = prev.gnome.overrideScope (finalGnome: prevGnome: {
      # Disable GTK support and add PipeWire GStreamer plugin.
      rygel = prevGnome.rygel.overrideAttrs(prevAttrs: {
        nativeBuildInputs = (prev.lib.lists.remove prev.wrapGAppsHook3 prevAttrs.nativeBuildInputs) ++ [ prev.wrapGAppsNoGuiHook ];
        buildInputs = (prev.lib.lists.remove final.gtk3 prevAttrs.buildInputs) ++ [ prev.pipewire prev.gdk-pixbuf ];
        mesonFlags = prevAttrs.mesonFlags ++ [
          "-Dgtk=disabled"
          "-Dx11=disabled"
        ];
        patches = prevAttrs.patches or [] ++ [
          (prev.fetchpatch2 {
            url = "https://gitlab.gnome.org/jwillikers/rygel/-/commit/8c7052ac7d61f190adeb1ef4251e6c7c77993872.patch";
            hash = "sha256-dfsZ0FKYBW8KzpPk/5WfX454BOscCXVkkPBuftVCRoQ=";
          })
        ];
      });
    });
    # todo Make it possible to disable graphviz support in libcamera.
    graphviz = prev.graphviz.override { withXorg = false; };
    gst_all_1 = prev.gst_all_1 // {
      gst-plugins-base = prev.gst_all_1.gst-plugins-base.override {
        enableX11 = false;
        enableWayland = false;
      };
      gst-plugins-good = prev.gst_all_1.gst-plugins-good.override {
        enableX11 = false;
        enableWayland = false;
      };
      gst-plugins-rs = prev.gst_all_1.gst-plugins-rs.override {
        withGtkPlugins = false;
      };
    };
    gtk3 = (prev.gtk3.override {
      broadwaySupport = false;
      cupsSupport = false;
      trackerSupport = false;
      # todo Why does it break the build when I disable X11 support?
      # x11Support = false;
      xineramaSupport = false;
      # waylandSupport = false;
    # }).overrideAttrs (prevAttrs: {
      # mesonFlags = prevAttrs.mesonFlags ++ [ "-Dwayland_backend=false" ];
    });
    gtk4 = (prev.gtk4.override {
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
    });
    # libepoxy = prev.libepoxy.override {
    #   x11Support = false;
    # };
    # Add PipeWire GStreamer plugin.
    mopidy = prev.mopidy.overrideAttrs (prevAttrs: {
        buildInputs = prevAttrs.buildInputs ++ [ prev.pipewire ];
    });
    nushell = prev.nushell.override {
      withDefaultFeatures = false;
    };
    pipewire = prev.pipewire.override {
      # todo Add support for disabling x11Support in vulkan-loader package.
      vulkanSupport = false;
      x11Support = false;
    };
    # Not sure how to entirely disable openconnect which is pulled in by NetworkManager.
    # So instead, just disable the GTK dependency that it indirectly pulls in.
    stoken = prev.stoken.override { withGTK3 = false; };
    libxkbcommon = prev.libxkbcommon.overrideAttrs(prevAttrs : {
      nativeBuildInputs = prev.lib.lists.remove prev.xorg.xorgserver prevAttrs.nativeBuildInputs;
      buildInputs = prev.lib.lists.remove prev.xorg.libxcb prevAttrs.buildInputs;
      mesonFlags = prevAttrs.mesonFlags ++ [ "-Denable-x11=false" ];
    });
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
    shairport-sync-airplay-2 = prev.shairport-sync.override { enableAirplay2 = true; };
  };

  realtime = _final: prev: {
    rpi-kernels.v6_6_54.bcm2711 = prev.rpi-kernels.v6_6_54.bcm2711.override (prevKernel: {
      autoModules = false;
      kernelPreferBuiltin = true;

      modDirVersion = "6.6.54-rt44";
      structuredExtraConfig =
        with prev.lib.kernel;
        {
          # Enable HDA soundcard support
          # This is magically enabled already.
          # By NixOS most likely, but I'm setting it here just to be clear.
          # It isn't enabled by default in Raspberry Pi OS.
          SND_HDA_GENERIC = yes;
          # SND_HDA_INTEL = yes;
          # SND_HDA_PREALLOC_SIZE = 2048;

          # todo What happens if I comment these out next?

          # EXT2_FS = no;
          # EXT3_FS = no;
          # F2FS_FS = prev.lib.mkForce no;
          # GFS2_FS = no;
          # JFS_FS = no;
          # MINIX_FS = no;
          # NFS_FS = no;
          # NFS_V2 = no;
          # NFS_V3 = no;
          # NFS_V4 = no;
          # NFSD = no;
          # REISERFS_FS = no;
          # SQUASHFS = no;
          # XFS_FS = no;

          # Disable infiniband.
          # INFINIBAND = prev.lib.mkForce no;
          # INFINIBAND_IPOIB = prev.lib.mkForce no;
          # INFINIBAND_IPOIB_CM = prev.lib.mkForce no;

          # # Disable Nouveau
          # DRM_NOUVEAU = no;

          # # Disable AMD
          # DRM_AMDGPU = no;
          # # DRM_AMDGPU_SI = prev.lib.mkForce no;
          # # DRM_AMDGPU_CIK = prev.lib.mkForce no;
          # # DRM_AMD_DC_DCN1_0 = prev.lib.mkForce no;
          # # DRM_AMD_DC_DCN2_0 = prev.lib.mkForce no;
          # # DRM_AMD_DC_DCN2_1 = prev.lib.mkForce no;
          # # DRM_AMD_DC_DCN3_0 = prev.lib.mkForce no;
          # # DRM_AMD_DC_DCN = prev.lib.mkForce no;
          # # DRM_AMD_DC_FP = prev.lib.mkForce no;
          # # DRM_AMD_DC_HDCP = prev.lib.mkForce no;
          # # DRM_AMD_DC_SI = prev.lib.mkForce no;
          # # DRM_AMD_ACP = prev.lib.mkForce no;
          # # DRM_AMD_SECURE_DISPLAY = prev.lib.mkForce no;
          # # DRM_AMD_ISP = prev.lib.mkForce no;
          # # DRM_NOUVEAU_GSP_DEFAULT = prev.lib.mkForce no;
          # # DEVICE_PRIVATE = prev.lib.mkForce no;
          # # DRM_NOUVEAU_SVM = prev.lib.mkForce no;

          # # Audio
          # SND_HDA_CODEC_CS8409 = prev.lib.mkForce no;

          # # misc
          # X86_AMD_PLATFORM_DEVICE = prev.lib.mkForce no;
          # X86_PLATFORM_DRIVERS_DELL = prev.lib.mkForce no;
          # X86_PLATFORM_DRIVERS_HP = prev.lib.mkForce no;
          # SUN8I_DE2_CCU = prev.lib.mkForce no;
          # CHROME_PLATFORMS = prev.lib.mkForce no;
          # CROS_EC = prev.lib.mkForce no;
          # CROS_EC_I2C = prev.lib.mkForce no;
          # CROS_EC_SPI = prev.lib.mkForce no;
          # CROS_EC_LPC = prev.lib.mkForce no;
          # CROS_EC_ISHTP = prev.lib.mkForce no;
          # CROS_KBD_LED_BACKLIGHT = prev.lib.mkForce no;
          # TCG_TIS_SPI_CR50 = prev.lib.mkForce no;

          # realtime
          # PREEMPT_RT was merged in to kernel 6.12.
          # https://github.com/NixOS/nixpkgs/blob/master/pkgs/os-specific/linux/kernel/linux-rt-6.1.nix
          PREEMPT_RT = yes;
          EXPERT = yes; # PREEMPT_RT depends on it (in kernel/Kconfig.preempt)
          # Fix error: option not set correctly: PREEMPT_VOLUNTARY (wanted 'y', got 'n').
          PREEMPT_VOLUNTARY = prev.lib.mkForce no; # PREEMPT_RT deselects it.
          # Fix error: unused option: RT_GROUP_SCHED.
          RT_GROUP_SCHED = prev.lib.mkForce (option no); # Removed by sched-disable-rt-group-sched-on-rt.patch.
          VIRTUALIZATION = no;
        }
        // prevKernel.structuredExtraConfig;
      kernelPatches =
        let
          rt-patch = {
            name = "rt";
            patch = prev.fetchurl {
              url = "mirror://kernel/linux/kernel/projects/rt/6.6/older/patch-6.6.53-rt44.patch.xz";
              sha256 = "sha256-LydfWRvOAMby42eDo0arQdpPXuA6v7SWIyDh/eHa07s=";
            };
          };
        in
        [ rt-patch ] ++ prevKernel.kernelPatches;
    });
    rpi-kernels.v6_6_54.bcm2712 = prev.rpi-kernels.v6_6_54.bcm2712.override (prevKernel: {
      autoModules = false;
      kernelPreferBuiltin = true;
      modDirVersion = "6.6.54-rt44";
      structuredExtraConfig =
        with prev.lib.kernel;
        {
          # Enable HDA soundcard support
          SND_HDA_GENERIC = yes;
          # SND_HDA_INTEL = yes;
          # SND_HDA_PREALLOC_SIZE = 2048;

          # # Disable infiniband.
          # INFINIBAND = prev.lib.mkForce no;
          # INFINIBAND_IPOIB = prev.lib.mkForce no;
          # INFINIBAND_IPOIB_CM = prev.lib.mkForce no;

          # # Disable Nouveau
          # DRM_NOUVEAU = no;

          # # Disable AMD
          # DRM_AMDGPU = no;
          # DRM_AMDGPU_SI = prev.lib.mkForce no;
          # DRM_AMDGPU_CIK = prev.lib.mkForce no;
          # DRM_AMD_DC_DCN1_0 = prev.lib.mkForce no;
          # DRM_AMD_DC_DCN2_0 = prev.lib.mkForce no;
          # DRM_AMD_DC_DCN2_1 = prev.lib.mkForce no;
          # DRM_AMD_DC_DCN3_0 = prev.lib.mkForce no;
          # DRM_AMD_DC_DCN = prev.lib.mkForce no;
          # DRM_AMD_DC_FP = prev.lib.mkForce no;
          # DRM_AMD_DC_HDCP = prev.lib.mkForce no;
          # DRM_AMD_DC_SI = prev.lib.mkForce no;
          # DRM_AMD_ACP = prev.lib.mkForce no;
          # DRM_AMD_SECURE_DISPLAY = prev.lib.mkForce no;
          # DRM_AMD_ISP = prev.lib.mkForce no;
          # DRM_NOUVEAU_GSP_DEFAULT = prev.lib.mkForce no;
          # DEVICE_PRIVATE = prev.lib.mkForce no;
          # DRM_NOUVEAU_SVM = prev.lib.mkForce no;

          # # Audio
          # SND_HDA_CODEC_CS8409 = prev.lib.mkForce no;

          # # misc
          # X86_AMD_PLATFORM_DEVICE = prev.lib.mkForce no;
          # X86_PLATFORM_DRIVERS_DELL = prev.lib.mkForce no;
          # X86_PLATFORM_DRIVERS_HP = prev.lib.mkForce no;
          # SUN8I_DE2_CCU = prev.lib.mkForce no;
          # CHROME_PLATFORMS = prev.lib.mkForce no;
          # CROS_EC = prev.lib.mkForce no;
          # CROS_EC_I2C = prev.lib.mkForce no;
          # CROS_EC_SPI = prev.lib.mkForce no;
          # CROS_EC_LPC = prev.lib.mkForce no;
          # CROS_EC_ISHTP = prev.lib.mkForce no;
          # CROS_KBD_LED_BACKLIGHT = prev.lib.mkForce no;
          # TCG_TIS_SPI_CR50 = prev.lib.mkForce no;

          # todo try
          # SCSI = no;

          # realtime
          # PREEMPT_RT was merged in to kernel 6.12.
          # https://github.com/NixOS/nixpkgs/blob/master/pkgs/os-specific/linux/kernel/linux-rt-6.1.nix
          PREEMPT_RT = yes;
          EXPERT = yes; # PREEMPT_RT depends on it (in kernel/Kconfig.preempt)
          # Fix error: option not set correctly: PREEMPT_VOLUNTARY (wanted 'y', got 'n').
          PREEMPT_VOLUNTARY = prev.lib.mkForce no; # PREEMPT_RT deselects it.
          # Fix error: unused option: RT_GROUP_SCHED.
          RT_GROUP_SCHED = prev.lib.mkForce (option no); # Removed by sched-disable-rt-group-sched-on-rt.patch.
          VIRTUALIZATION = no;
        }
        // prevKernel.structuredExtraConfig;
      kernelPatches =
        let
          rt-patch = {
            name = "rt";
            patch = prev.fetchurl {
              url = "mirror://kernel/linux/kernel/projects/rt/6.6/older/patch-6.6.53-rt44.patch.xz";
              sha256 = "sha256-LydfWRvOAMby42eDo0arQdpPXuA6v7SWIyDh/eHa07s=";
            };
          };
        in
        [ rt-patch ] ++ prevKernel.kernelPatches;
    });
    # The realtime patchset fails to apply on kernel 6.10.12.
    # I will probably just wait for 6.12.
    rpi-kernels.v6_10_12.bcm2712 = prev.rpi-kernels.v6_10_12.bcm2712.override (prevKernel: {
      modDirVersion = "6.10.12-rt14";
      structuredExtraConfig =
        with prev.lib.kernel;
        {
          # Enable HDA soundcard support
          SND_HDA_GENERIC = yes;
          # SND_HDA_INTEL = yes;
          # SND_HDA_PREALLOC_SIZE = 2048;

          # realtime
          # PREEMPT_RT was merged in to kernel 6.12.
          # https://github.com/NixOS/nixpkgs/blob/master/pkgs/os-specific/linux/kernel/linux-rt-6.1.nix
          PREEMPT_RT = yes;
          EXPERT = yes; # PREEMPT_RT depends on it (in kernel/Kconfig.preempt)
          # Fix error: option not set correctly: PREEMPT_VOLUNTARY (wanted 'y', got 'n').
          PREEMPT_VOLUNTARY = prev.lib.mkForce no; # PREEMPT_RT deselects it.
          # Fix error: unused option: RT_GROUP_SCHED.
          RT_GROUP_SCHED = prev.lib.mkForce (option no); # Removed by sched-disable-rt-group-sched-on-rt.patch.
          VIRTUALIZATION = no;
        }
        // prevKernel.structuredExtraConfig;
      kernelPatches =
        let
          rt-patch = {
            name = "rt";
            patch = prev.fetchurl {
              url = "mirror://kernel/linux/kernel/projects/rt/6.10/older/patch-6.10.2-rt14.patch.xz";
              sha256 = "sha256-qQ6mXEvk/VQykA322EgG6fWkuaKHTwY/nfZx216N8Jo=";
            };
          };
        in
        [ rt-patch ] ++ prevKernel.kernelPatches;
    });
  };
}

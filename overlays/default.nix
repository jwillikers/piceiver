{ inputs, ... }:
{
  # Add custom packages from the pkgs directory
  additions = final: _prev: import ../pkgs final.pkgs;

  # deploy-rs-overlay = inputs.deploy-rs.overlays.default;
  # deploy-rs-package = final: prev: { deploy-rs = { inherit (final) deploy-rs; lib = final.deploy-rs.lib; }; };

  # Disable unnecessary graphics support.
  headless = _final: prev: {
    dbus = prev.dbus.override { x11Support = false; };
    # todo Make it possible to disable graphviz support in libcamera.
    graphviz = prev.graphviz.override { withXorg = false; };
    gst-plugins-base = prev.gst-plugins-base.override { enableX11 = false; };
    pipewire = prev.pipewire.override {
      # todo Add support for disabling x11Support in vulkan-loader package.
      vulkanSupport = false;
      x11Support = false;
    };
    # Not sure how to entirely disable openconnect which is pulled in by NetworkManager.
    # So instead, just disable the GTK dependency that it indirectly pulls in.
    stoken = prev.stoken.override { withGTK3 = false; };
  };

  # Expose the PipeWire gstreamer plugin to Mopidy.
  mopidy-pipewire-gstreamer-plugin = _final: prev: {
    mopidy = prev.mopidy.overrideAttrs (_prevAttrs: {
      preFixup = ''
        gappsWrapperArgs+=(
          # Gstreamer PipeWire plugin
          --prefix GST_PLUGIN_SYSTEM_PATH_1_0 : "${prev.pipewire}/lib/gstreamer-1.0"
        )
      '';
    });
  };

  # Expose the PipeWire gstreamer plugin to Rygel.
  rygel-pipewire-gstreamer-plugin = _final: prev: {
    gnome.rygel = prev.gnome.rygel.overrideAttrs (_prevAttrs: {
      preFixup = ''
        gappsWrapperArgs+=(
          # Gstreamer PipeWire plugin
          --prefix GST_PLUGIN_SYSTEM_PATH_1_0 : "${prev.pipewire}/lib/gstreamer-1.0"
        )
      '';
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

  # Enable AirPlay 2 support in shairport-sync.
  shairport-sync-airplay2 = _final: prev: {
    shairport-sync = prev.shairport-sync.override { enableAirplay2 = true; };
  };

  realtime = _final: prev: {
    rpi-kernels.v6_6_54.bcm2711 = prev.rpi-kernels.v6_6_54.bcm2711.override (prevKernel: {
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
      modDirVersion = "6.6.54-rt44";
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

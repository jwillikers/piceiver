{
  inputs,
  pkgs,
  audioHAT,
  raspberryPiModel,
  lib,
  ...
}:
let
  # Vendor kernel with matching firmware from nixos-raspberrypi.
  # Keep this in sync with the kernel version overridden by the realtime overlay in overlays/default.nix.
  kernelBundle = pkgs.linuxAndFirmware.v6_12_87;
in
{
  # if raspberryPiModel == "5" then "bcm2712" else "bcm2711"
  imports = [
    inputs.nixos-raspberrypi.nixosModules.sd-image
  ]
  ++ lib.optionals (raspberryPiModel == "5") [
    inputs.nixos-raspberrypi.nixosModules.raspberry-pi-5.base
    inputs.nixos-raspberrypi.nixosModules.raspberry-pi-5.bluetooth
  ]
  ++ lib.optionals (raspberryPiModel == "4") [
    inputs.nixos-raspberrypi.nixosModules.raspberry-pi-4.base
    inputs.nixos-raspberrypi.nixosModules.raspberry-pi-4.bluetooth
  ];

  boot = {
    loader.raspberry-pi.firmwarePackage = kernelBundle.raspberrypifw;
    kernelPackages = kernelBundle."linuxPackages_rpi${raspberryPiModel}";
    # The installer base profile pulled in by the sd-image module enables ZFS by default.
    # Avoid building the ZFS kernel module for the custom kernel.
    supportedFilesystems.zfs = false;
  };

  nixpkgs.overlays = lib.mkAfter [
    (_final: _prev: {
      # This is used in (modulesPath + "/hardware/all-firmware.nix") when at least
      # enableRedistributableFirmware is enabled
      # I know no easier way to override this package
      inherit (kernelBundle) raspberrypiWirelessFirmware;
      # Some derivations want to use it as an input,
      # e.g. raspberrypi-dtbs, omxplayer, sd-image-* modules
      inherit (kernelBundle) raspberrypifw;
    })
  ];

  hardware.raspberry-pi.config = {
    all = {
      base-dt-params = {
        # Uncomment some or all of these to enable the optional hardware interfaces
        # i2c_arm = {
        #   enable = true;
        #   value = "on";
        # };
        i2s = {
          enable = true;
          value = "on";
        };
        # spi = {
        #   enable = true;
        #   value = "on";
        # };

        # todo enable autoprobing of bluetooth driver?
        # Remove this if Bluetooth works without it.
        # https://github.com/raspberrypi/linux/blob/c8c99191e1419062ac8b668956d19e788865912a/arch/arm/boot/dts/overlays/README#L222-L224
        # krnbt = {
        #   enable = true;
        #   value = "on";
        # };

        # todo Steal back some RAM.
        # gpu_mem = {
        #   enable = true;
        #   value = 16;
        # };
        # start_x = {
        #   enable = true;
        #   value = 0;
        # };

        pciex1_gen = lib.mkIf (raspberryPiModel == "5") {
          enable = true;
          value = 3;
        };
      };
      dt-overlays = {
        # Disable the onboard Bluetooth to avoid issues.
        disable-bt = {
          enable = true;
          params = { };
        };
        rpi-dacpro = lib.mkIf (audioHAT == "DAC Pro") {
          enable = true;
          params = { };
        };
        rpi-digiampplus = lib.mkIf (audioHAT == "DigiAmp+") {
          enable = true;
          params.auto_mute_amp.enable = true;
          # params.unmute_amp.enable = true;
        };
        pcie-32bit-dma = lib.mkIf (raspberryPiModel == "5") {
          enable = true;
          params = { };
        };
        vc4-kms-v3d = {
          enable = true;
          params.noaudio.enable = true;
        };
      };
    };
  };
}

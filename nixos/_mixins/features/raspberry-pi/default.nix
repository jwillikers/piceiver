{
  audioHAT,
  raspberryPiModel,
  lib,
  ...
}:
{
  raspberry-pi-nix = {
    board = if raspberryPiModel == "5" then "bcm2712" else "bcm2711";
  };

  # todo Don't build drivers/gpu/amd, drivers/gpu/nouveau, net/can driver support etc.
  hardware.raspberry-pi.config.all = {
    base-dt-params = {
      # enable autoprobing of bluetooth driver
      # https://github.com/raspberrypi/linux/blob/c8c99191e1419062ac8b668956d19e788865912a/arch/arm/boot/dts/overlays/README#L222-L224
      krnbt = {
        enable = true;
        value = "on";
      };

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
}

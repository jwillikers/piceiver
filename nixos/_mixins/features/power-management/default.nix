_: {
  boot.kernelParams = [ "usbcore.autosuspend=-1" ];
  powerManagement.enable = false;
  systemd.targets = {
    hibernate.enable = false;
    hybrid-sleep.enable = false;
    suspend-then-hibernate.enable = false;
  };
}

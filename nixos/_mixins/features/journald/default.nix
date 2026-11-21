_: {
  # Keep the journal in RAM to reduce writes to the SD card.
  # journald writes to its memory-mapped files amplify the writes many times over the size of the logs.
  # Logs are lost on reboot.
  services.journald = {
    storage = "volatile";
    extraConfig = ''
      RuntimeMaxUse=64M
    '';
  };
}

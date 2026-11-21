_: {
  # Music Assistant connects to the Sendspin player advertised over mDNS.
  # Keep in sync with the port in home-manager/_mixins/services/sendspin/default.nix.
  networking.firewall.allowedTCPPorts = [ 8928 ];
}

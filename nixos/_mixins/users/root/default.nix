_: {
  users.users.root = {
    initialPassword = "V2psT!t0";
    # Only accept the key from the local network: the IPv4 subnet, the IPv6 unique local prefix, and IPv6 link-local addresses.
    # Update these to match your network.
    openssh.authorizedKeys.keys = [
      ''from="10.1.0.0/24,fd00:1010::/64,fe80::/10" ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAP56w70Wms1Dez5p7eGGgF0rmJd87VLX5CaVrDIRYaa jordan@precision5350.jwillikers.io''
    ];
  };
}

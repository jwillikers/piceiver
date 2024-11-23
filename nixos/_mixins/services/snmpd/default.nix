{ pkgs, ... }:
{
  environment.etc."snmp/snmpd.conf".source = ./snmpd.conf;
  networking.firewall.allowedUDPPorts = [ 161 ]; # SNMP
  systemd.services.snmpd = {
    enable = true;
    wantedBy = [ "multi-user.target" ];
    description = "Net-SNMP daemon";
    after = [ "network.target" ];
    restartIfChanged = true;
    serviceConfig = {
      User = "root";
      Group = "root";
      Restart = "on-failure";
      ExecStart = "${pkgs.net-snmp}/bin/snmpd -Lf /var/log/snmpd.log -f -c /etc/snmp/snmpd.conf";
    };
  };
}

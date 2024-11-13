_: {
  users.groups.core.gid = 818;
  users.users.core = {
    description = "Core";
    extraGroups = [
      "audio"
      "systemd-journal"
    ];
    uid = 818;
    group = "core";
    createHome = true;
    home = "/home/core";
    isSystemUser = true;
    linger = true;
    shell = null;
  };
}

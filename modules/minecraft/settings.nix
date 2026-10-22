{
  user = "zezocas";

  image = "itzg/minecraft-server";
  defaultMemory = "6G";
  # Where world ports listen on this machine. "::" = all IPv6 addresses
  # (public IPv6 for players, [::1] for local use). "127.0.0.1" = this machine only.
  defaultBind = "::";

  # Ports opened to the internet over IPv6 (one per world). Also open these in
  # the router's IPv6 firewall. Empty list = nothing open.
  publicPorts = [ 25565 25566 25567 ];

  network = "mcnet";
  subnet = "172.30.0.0/24";
  bridge = "br-mc";

  dataRoot = "/srv/minecraft";
  backupDir = "/srv/minecraft-backups";
  backupTime = "04:00";
  backupKeep = 7;

  blockedRanges = "192.168.0.0/16 10.0.0.0/8 100.64.0.0/10";
}

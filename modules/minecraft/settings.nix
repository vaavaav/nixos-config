{
  user = "zezocas";

  image = "itzg/minecraft-server";
  defaultMemory = "6G";
  defaultBind = "127.0.0.1";

  network = "mcnet";
  subnet = "172.30.0.0/24";
  bridge = "br-mc";

  dataRoot = "/srv/minecraft";
  backupDir = "/srv/minecraft-backups";
  backupTime = "04:00";
  backupKeep = 7;

  blockedRanges = "192.168.0.0/16 10.0.0.0/8 100.64.0.0/10";

  playitImage = "ghcr.io/playit-cloud/playit-agent:1.0.12";
  playitEnvFile = "/etc/playit/playit.env";
}

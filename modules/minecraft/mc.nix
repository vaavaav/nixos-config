{ config, pkgs, ... }:
let
  s = import ./settings.nix;

  mc = pkgs.writeShellApplication {
    name = "mc";
    runtimeInputs = [ config.virtualisation.docker.package pkgs.python3 pkgs.gnutar pkgs.gzip pkgs.coreutils ];
    text = ''
      export MC_IMAGE=${s.image}
      export MC_DEFAULT_MEMORY=${s.defaultMemory}
      export MC_DEFAULT_BIND=${s.defaultBind}
      export MC_NETWORK=${s.network}
      export MC_NETWORK_SUBNET=${s.subnet}
      export MC_NETWORK_BRIDGE=${s.bridge}
      export MC_DATA_ROOT=${s.dataRoot}
      export MC_BACKUP_DIR=${s.backupDir}
      export MC_BACKUP_TIME=${s.backupTime}
      export MC_BACKUP_KEEP=${toString s.backupKeep}
      exec python3 ${./mc.py} "$@"
    '';
  };
in
{
  assertions = [
    {
      assertion = builtins.stringLength s.bridge <= 15;
      message = "minecraft settings.nix: bridge must be at most 15 characters.";
    }
    {
      assertion = builtins.match "([01][0-9]|2[0-3]):[0-5][0-9]" s.backupTime != null;
      message = "minecraft settings.nix: backupTime must look like 04:00.";
    }
  ];

  environment.systemPackages = [ mc ];

  systemd.tmpfiles.rules = [
    "d ${s.dataRoot} 0755 ${s.user} users -"
    "d ${s.backupDir} 0700 ${s.user} users -"
  ];

  systemd.services.minecraft-backup = {
    after = [ "docker.service" ];
    requires = [ "docker.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${mc}/bin/mc backup --all";
      Nice = 10;
      IOSchedulingClass = "idle";
    };
  };

  systemd.timers.minecraft-backup = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*-*-* ${s.backupTime}:00";
      Persistent = true;
      RandomizedDelaySec = "10m";
    };
  };
}

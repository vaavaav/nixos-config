{ ... }:
let
  s = import ./settings.nix;
in
{
  virtualisation.oci-containers = {
    backend = "docker";
    containers.playit = {
      image = s.playitImage;
      environmentFiles = [ s.playitEnvFile ];
      extraOptions = [
        "--network=${s.network}"
        "--cap-drop=ALL"
        "--security-opt=no-new-privileges"
      ];
    };
  };

  systemd.tmpfiles.rules = [ "d ${builtins.dirOf s.playitEnvFile} 0700 root root -" ];

  systemd.services.docker-playit = {
    after = [ "docker-network-mc.service" "mc-network-isolation.service" ];
    requires = [ "docker-network-mc.service" ];
    unitConfig.ConditionPathExists = s.playitEnvFile;
  };
}

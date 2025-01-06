{ config, ... }:
let
  homeDirectory = config.home.homeDirectory;
in
{
  services.ssh-agent.enable = true;
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = {
      "*" = {
        forwardAgent = false;
        addKeysToAgent = "yes";
        compression = false;
        serverAliveInterval = 0;
        serverAliveCountMax = 3;
        hashKnownHosts = false;
        userKnownHostsFile = "~/.ssh/known_hosts";
        controlMaster = "no";
        controlPath = "~/.ssh/master-%r@%n:%p";
        controlPersist = "no";
      };
      "cloud*" = {
        user = "gsd";
        hostname = "%h.cluster.lsd.di.uminho.pt";
        identityFile = [ "${homeDirectory}/.ssh/cloudinhas" ];
        forwardAgent = true;
        forwardX11 = true;
        forwardX11Trusted = true;
      };
      "deucalion" = {
        user = "jose.p.peixoto";
        hostname = "login.deucalion.macc.fccn.pt";
        identityFile = [ "${homeDirectory}/.ssh/deucalion" ];
        forwardAgent = true;
        forwardX11 = true;
        forwardX11Trusted = true;
      };
      "frontera" = {
        user = "jppeixoto";
        hostname = "frontera.tacc.utexas.edu";
        identityFile = [ "${homeDirectory}/.ssh/tacc" ];
        forwardAgent = true;
        forwardX11 = true;
        forwardX11Trusted = true;
      };
      "vista" = {
        user = "jppeixoto";
        hostname = "vista.tacc.utexas.edu";
        identityFile = [ "${homeDirectory}/.ssh/tacc" ];
        forwardAgent = true;
        forwardX11 = true;
        forwardX11Trusted = true;
      };
      "taiwania" = {
        user = "jose.p.peixoto";
        hostname = "140.110.109.147";
        identityFile = [ "${homeDirectory}/.ssh/taiwania" ];
        forwardAgent = true;
        forwardX11 = true;
        forwardX11Trusted = true;
      };
    };
  };
}

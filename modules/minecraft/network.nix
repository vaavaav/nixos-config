{ config, pkgs, ... }:
let
  s = import ./settings.nix;

  isolation = action: suffix: ''
    for range in ${s.blockedRanges}; do
      iptables -${action} DOCKER-USER -i ${s.bridge} -d "$range" -m conntrack --ctstate NEW -j DROP${suffix}
    done
  '';
in
{
  systemd.services.docker-network-mc = {
    after = [ "docker.service" ];
    requires = [ "docker.service" ];
    wantedBy = [ "multi-user.target" ];
    path = [ config.virtualisation.docker.package ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      docker network inspect ${s.network} >/dev/null 2>&1 ||
        docker network create --subnet ${s.subnet} \
          --opt com.docker.network.bridge.name=${s.bridge} ${s.network}
    '';
  };

  networking.firewall = {
    enable = true;
    extraCommands = ''
      iptables -I nixos-fw 1 -i ${s.bridge} -m conntrack --ctstate NEW -j nixos-fw-refuse
    '';
  };

  systemd.services.mc-network-isolation = {
    after = [ "docker.service" ];
    requires = [ "docker.service" ];
    partOf = [ "docker.service" ];
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.iptables ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      iptables -N DOCKER-USER 2>/dev/null || true
      ${isolation "D" " 2>/dev/null || true"}
      ${isolation "I" ""}
    '';
    preStop = isolation "D" " 2>/dev/null || true";
  };
}

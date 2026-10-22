let
  s = import ./settings.nix;
in
{
  virtualisation.docker = {
    enable = true;
    autoPrune.enable = true;
    # The worlds' network is IPv4-only; docker-proxy is what carries IPv6
    # connections on [::] into the containers. This is Docker's default,
    # set here so it can't be turned off by accident.
    daemon.settings.userland-proxy = true;
  };

  users.users.${s.user}.extraGroups = [ "docker" ];
}

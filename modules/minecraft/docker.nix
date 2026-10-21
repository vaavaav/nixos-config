let
  s = import ./settings.nix;
in
{
  virtualisation.docker = {
    enable = true;
    autoPrune.enable = true;
  };

  users.users.${s.user}.extraGroups = [ "docker" ];
}

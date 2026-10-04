{ pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/bluetooth.nix
    ../../modules/docker.nix
  ];

  # Printing
  environment.systemPackages = with pkgs; [ hplipWithPlugin ];
  services.printing = {
    enable = true;
    drivers = with pkgs; [ hplipWithPlugin ];
  };
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };
  programs.system-config-printer.enable = true;

  # VPN
  services.mullvad-vpn.enable = true;

  # Tailscale
  services.tailscale.enable = true;

  # Steam
  programs.steam = {
    enable = true;
    extraCompatPackages = [ pkgs.proton-ge-bin ];
  };

}

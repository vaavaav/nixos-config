{ pkgs, ... }:

let
  hostname = "E16";
in
{
  imports = [
    ./../common.nix
    ./hardware-configuration.nix
  ];

  # Host-specific packages
  environment.systemPackages = with pkgs; [
    bluez
    bluez-tools
    hplipWithPlugin
  ];

  # Networking
  networking = {
    hostName = hostname;
    networkmanager.plugins = with pkgs; [
      networkmanager-vpnc
      networkmanager-openvpn
    ];
  };

  # Docker
  virtualisation.docker = {
    rootless = {
      enable = true;
      setSocketVariable = true;
    };
  };

  # Bluetooth
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Enable = "Source,Sink,Media,Socket";
      };
    };
  };
  services.blueman.enable = true;

  # Printing
  services.printing = {
    enable = true;
    drivers = with pkgs; [
      hplipWithPlugin
    ];
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

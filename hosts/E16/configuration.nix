{ pkgs, stateVersion, hostname, user, lib, ... }:

{
  imports = [
    ./../common.nix
    ./hardware-configuration.nix
  ];

  environment.variables = {
    ETH_INTERFACE = "enp1s0";
    WLAN_INTERFACE = "wlp2s0";
  };

  # Docker
  virtualisation.docker = {
    rootless = {
      enable = true;
      setSocketVariable = true;
    };
  };


  # Boot
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 3;

  # System packages
  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [
    bluez
    bluez-tools
    hplipWithPlugin
  ];

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
  services = {
    printing = {
      enable = true;
      drivers = with pkgs; [
        hplipWithPlugin
      ];
    };
    avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };
  };
  users.users.${user}.extraGroups = [ "lp" ];

  # Printing
  programs.system-config-printer.enable = true;

}

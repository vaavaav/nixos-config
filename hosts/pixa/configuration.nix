{ pkgs, ... }:

let
  hostname = "pixa";
in
{
  imports = [
    ./../common.nix
    ./hardware-configuration.nix
  ];

  # Boot
  boot.loader.efi.canTouchEfiVariables = true;

  # For Archer T2U Nano
  boot.kernelModules = [ "rtw88_8821au" ];
  boot.blacklistedKernelModules = [
    "8821au"
    "rtl8xxxu"
  ];
  networking.networkmanager.wifi = {
    macAddress = "preserve";
    scanRandMacAddress = false;
  };

  # Networking
  networking = {
    hostName = hostname;
    networkmanager.plugins = with pkgs; [
      networkmanager-vpnc
      networkmanager-openvpn
    ];
  };
}

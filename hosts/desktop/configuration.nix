{ pkgs, stateVersion, hostname, user, lib, ... }:

{
  imports = [
    ./../common.nix
    ./hardware-configuration.nix
  ];

  environment.variables = {
    ETH_INTERFACE = "";
    WLAN_INTERFACE = "";
  };

  # Boot
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "nodev";
  boot.loader.useOSProber = true;
  time.hardwareClockInLocalTime = true;

  # System packages
  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [
  ];

  users.users.${user}.extraGroups = [ "lp" ];
}

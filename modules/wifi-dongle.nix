{ config, pkgs, ... }:

# Archer T2U Nano USB wifi dongle (Realtek RTL8811AU, USB id 2357:011e)
#
# Uses the separate Realtek driver (module "8821au"), instead
# of the in-kernel rtw88_8821au, which froze the whole machine after a few
# hours even with power saving off. That driver only builds on kernels older
# than 6.15, so this pins the 6.12 long-term-support kernel.
{
  boot.kernelPackages = pkgs.linuxPackages_6_12;
  boot.extraModulePackages = [ config.boot.kernelPackages.rtl8821au ];
  boot.kernelModules = [ "8821au" ];
  boot.blacklistedKernelModules = [
    "rtw88_8821au"
    "rtl8xxxu"
  ];

  boot.extraModprobeConfig = ''
    options 8821au rtw_power_mgnt=0 rtw_enusbss=0
  '';

  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="2357", ATTR{idProduct}=="011e", ATTR{power/control}="on"
  '';

  networking.networkmanager.wifi = {
    macAddress = "preserve";
    scanRandMacAddress = false;
    powersave = false;
  };
}

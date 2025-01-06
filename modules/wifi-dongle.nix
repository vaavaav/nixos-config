{ ... }:

# Archer T2U Nano USB wifi dongle
{
  boot.kernelModules = [ "rtw88_8821au" ];
  boot.blacklistedKernelModules = [
    "8821au"
    "rtl8xxxu"
  ];
  networking.networkmanager.wifi = {
    macAddress = "preserve";
    scanRandMacAddress = false;
  };
}

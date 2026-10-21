{ ... }:

# Archer T2U Nano USB wifi dongle
{
  boot.kernelModules = [ "rtw88_8821au" ];
  boot.blacklistedKernelModules = [
    "8821au"
    "rtl8xxxu"
  ];

  # Desliga o deep power save do driver rtw88 (causa picos de latência)
  boot.extraModprobeConfig = ''
    options rtw88_core disable_lps_deep=y
  '';

  # Impede o autosuspend USB só para esta pen
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="2357", ATTR{idProduct}=="011e", ATTR{power/control}="on"
  '';

  networking.networkmanager.wifi = {
    macAddress = "preserve";
    scanRandMacAddress = false;
    powersave = false;
  };
}

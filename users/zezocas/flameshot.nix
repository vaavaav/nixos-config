{ config, ... }:
{
  services.flameshot = {
    enable = true;
    settings.General = {
      savePath = "${config.home.homeDirectory}/Pictures/Screenshots";
      showHelp = false;
      showStartupLaunchMessage = false;
      disabledTrayIcon = true;
      copyOnDoubleClick = true;
      uiColor = "#957fb8";
      contrastUiColor = "#16161d";
      drawColor = "#e46876";
      fontFamily = "Geist";
    };
  };

  home.file."Pictures/Screenshots/.keep".text = "";
}

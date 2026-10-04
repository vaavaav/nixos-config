{
  services.mako = {
    enable = true;
    settings = {
      font = "Geist 11";
      background-color = "#16161dee";
      text-color = "#dcd7ba";
      border-color = "#363646";
      border-size = 1;
      border-radius = 12;
      padding = "12,16";
      outer-margin = "6";
      width = 360;
      height = 160;
      max-icon-size = 40;
      icon-border-radius = 8;
      layer = "overlay";
      default-timeout = 6000;
      max-visible = 4;

      "urgency=low".text-color = "#9e9b93";
      "urgency=critical" = {
        border-color = "#e46876";
        default-timeout = 0;
      };
    };
  };
}

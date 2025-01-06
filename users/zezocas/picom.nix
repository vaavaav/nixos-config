{ pkgs, ... }:
{
  services.picom = {
    enable = true;
    fade = true;
    fadeSteps = [
      0.03
      0.03
    ];
    activeOpacity = 1.0;
    inactiveOpacity = 1.0;
    opacityRules = [
      "95:class_g = '${pkgs.kitty.pname}' && focused"
      "90:class_g = '${pkgs.kitty.pname}' && !focused"
    ];
    backend = "glx";
    vSync = true;
    settings = {
      frame-opacity = 0.9;
      focus-exclude = [ "class_g = 'Cairo-clock'" ];
      blur = {
        method = "dual_kawase";
        strength = 2;
      };
      blur-background = true;
      blur-background-frame = false;
      blur-background-fixed = true;
      blur-background-exclude = [
        "window_type = 'desktop' && class_g != '${pkgs.kitty.pname}'"
      ];
      log-level = "warn";
      wintypes = {
        tooltip = {
          fade = true;
          shadow = true;
          opacity = 0.75;
          focus = true;
          full-shadow = false;
        };
        dock.shadow = false;
        dnd.shadow = false;
        popup_menu.opacity = 0.9;
        dropdown_menu.opacity = 0.9;
      };
    };
  };
}

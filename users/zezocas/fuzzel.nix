{ pkgs, ... }:
{
  home.packages = [ pkgs.papirus-icon-theme ];

  programs.fuzzel = {
    enable = true;
    settings = {
      main = {
        font = "Geist:size=11";
        prompt = ''"❯  "'';
        placeholder = "Search";
        icon-theme = "Papirus-Dark";
        terminal = "kitty";
        layer = "overlay";
        lines = 8;
        width = 62;
        line-height = 30;
        horizontal-pad = 22;
        vertical-pad = 20;
        inner-pad = 16;
      };
      colors = {
        background = "16161df0";
        text = "b4b6b0ff";
        prompt = "727169ff";
        input = "dcd7baff";
        placeholder = "54546dff";
        match = "957fb8ff";
        selection = "957fb82e";
        selection-text = "f2ecd8ff";
        selection-match = "c5b4e8ff";
        border = "363646ff";
      };
      border = {
        width = 1;
        radius = 12;
        selection-radius = 10;
      };
    };
  };
}

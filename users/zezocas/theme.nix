{ pkgs, ... }:
{
  gtk = {
    enable = true;
    colorScheme = "dark";
    font = {
      name = "Geist";
      size = 11;
      package = pkgs.geist-font;
    };
    theme = {
      name = "Adwaita-dark";
      package = pkgs.gnome-themes-extra;
    };
    gtk4.theme = null;
  };

  qt = {
    enable = true;
    style.name = "adwaita-dark";
  };

  home.pointerCursor = {
    enable = true;
    gtk.enable = true;
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Classic";
    size = 24;
  };

  fonts.fontconfig = {
    enable = true;
    defaultFonts.sansSerif = [ "Geist" ];
    defaultFonts.monospace = [ "Iosevka" ];
  };

  dconf.settings = {
    "org/gnome/nautilus/preferences".default-folder-viewer = "list-view";
    "org/gnome/nautilus/list-view".default-zoom-level = "small";
    "org/gtk/gtk4/settings/file-chooser".view-type = "list";
  };
}

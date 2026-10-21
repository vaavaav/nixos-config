{
  pkgs,
  lib,
  ...
}:
let
  ghostscript-fonts = import ../../flakes/ghostscript-fonts/default.nix { inherit pkgs lib; };
in
{
  imports = [
    ./cli.nix
    ./fuzzel.nix
    ./kitty.nix
    ./niri.nix
    ./notifications.nix
    ./theme.nix
    ./waybar.nix
  ];

  home.packages = with pkgs; [
    ansible
    asciinema
    asciinema-agg
    autenticacao-gov-pt-bin
    bitwarden-desktop
    bottles
    cabal-install
    cargo
    claude-code
    cmake
    corefonts
    discord
    drawio
    fira-sans
    firefox
    font-manager
    gcc
    gimp
    gnumake
    ghostscript-fonts
    imv
    inkscape
    inter
    iosevka
    jdk
    kitty
    libertine
    libertinus
    libnotify
    libreoffice
    libtool
    markdown-oxide
    material-design-icons
    mullvad-vpn
    nerd-fonts.iosevka
    nerd-fonts.symbols-only
    nodejs_24
    noto-fonts
    obsidian
    pavucontrol
    playerctl
    rustc
    slack
    spotify
    stremio-linux-shell
    tdf
    teams-for-linux
    termshark
    texlab
    texliveFull
    thunderbird
    typst
    vagrant
    wdisplays
    zathura
    zoom-us
    zotero
  ];

  fonts.fontconfig = {
    enable = true;
    defaultFonts = {
      monospace = [ "Iosevka" ];
      sansSerif = [ "Geist" ];
    };
  };

  home.file = {
    ".local/share/fonts/NerdFonts" = {
      source = "${pkgs.nerd-fonts.symbols-only}/share/fonts/truetype/NerdFonts/Symbols";
      recursive = true;
    };
  };
}

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
    ./bash.nix
    ./flameshot.nix
    ./fuzzel.nix
    ./git.nix
    ./kitty.nix
    ./neovim.nix
    ./niri.nix
    ./notifications.nix
    ./ssh.nix
    ./theme.nix
    ./tmux.nix
    ./waybar.nix
  ];

  home = {
    username = "zezocas";
    homeDirectory = "/home/zezocas";
    stateVersion = "25.11";
    packages = with pkgs; [
      ansible
      asciinema
      asciinema-agg
      autenticacao-gov-pt-bin
      bash
      bitwarden-desktop
      bottles
      btop
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
      fzf
      gcc
      gimp
      gnumake
      ghostscript-fonts
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
      openssl
      pavucontrol
      playerctl
      rustc
      slack
      speedtest-cli
      spotify
      stremio-linux-shell
      tdf
      teams-for-linux
      termshark
      texlab
      texliveFull
      thunderbird
      tmux
      typst
      vagrant
      wdisplays
      zathura
      zip
      zoom-us
      zotero
    ];
  };

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

  home.activation.pruneOldGenerations = lib.hm.dag.entryAfter [ "nixos-rebuild" ] ''
    nix-env --delete-generations '+4'
  '';
}

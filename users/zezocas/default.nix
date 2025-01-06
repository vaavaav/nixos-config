{ pkgs, lib, config, ... }:
let
  ghostscript-fonts = import ../../flakes/ghostscript-fonts/default.nix { inherit pkgs lib; };
in
{
  imports = [
    ./git.nix
    ./ssh.nix
    ./i3.nix
    ./i3status.nix
    ./kitty.nix
    ./neovim.nix
    ./picom.nix
  ];

  home = {
    username = "zezocas";
    homeDirectory = "/home/zezocas";
    stateVersion = "25.11";
    keyboard = {
      layout = "us";
      variant = "intl";
      model = "pc105";
    };
    packages = with pkgs; [
      ansible
      arandr
      asciinema
      asciinema-agg
      autenticacao-gov-pt-bin
      bash
      bash-language-server
      bitwarden-desktop
      bottles
      btop
      cabal-install
      cargo
      claude-code
      ccls
      cmake
      cmake-language-server
      corefonts
      discord
      drawio
      fd
      feh
      fira-sans
      firefox
      flameshot
      font-manager
      fzf
      gammastep
      gcc
      gimp
      gnumake
      ghostscript-fonts
      haskell-language-server
      i3
      i3status-rust
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
      ltex-ls
      lua-language-server
      markdown-oxide
      material-design-icons
      mullvad-vpn
      networkmanagerapplet
      nerd-fonts.iosevka
      nerd-fonts.symbols-only
      nil
      nixfmt
      nodejs_24
      noto-fonts
      obsidian
      kdePackages.okular
      openssl
      pavucontrol
      playerctl
      (python3.withPackages (
        ps: with ps; [
          black
          isort
          python-lsp-server
          python-lsp-black
          pyls-isort
        ]
      ))
      ripgrep
      rofi
      rustc
      slack
      speedtest-cli
      spotify
      #stremio
      tdf
      teams-for-linux
      termshark
      texlab
      texliveFull
      thunderbird
      tmux
      typst
      vagrant
      xclip
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
      sansSerif = [ "Inter" ];
    };
  };

  home.file = {
    ".local/share/fonts/NerdFonts" = {
      source = "${pkgs.nerd-fonts.symbols-only}/share/fonts/truetype/NerdFonts/Symbols";
      recursive = true;
    };
    ".bashrc".source = ../../home/dotfiles/.bashrc;
    ".bash_profile".source = ../../home/dotfiles/.bash_profile;
    ".config" = {
      source = ../../home/dotfiles/.config;
      recursive = true;
    };
  };

  gtk = {
    enable = true;
    gtk3.extraConfig.gtk-application-prefer-dark-theme = 1;
    gtk4.theme = config.gtk.theme;
    theme.name = "Adwaita";
    iconTheme.name = "Adwaita";
  };

  home.activation.pruneOldGenerations = lib.hm.dag.entryAfter [ "nixos-rebuild" ] ''
    nix-env --delete-generations '+4'
  '';
}

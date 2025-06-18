{ homeStateVersion, user, pkgs, lib, autenticacao-gov-pt, ... }:
{

  nixpkgs.config.allowUnfree = true;

  home = {
    username = user;
    homeDirectory = "/home/${user}";
    stateVersion = homeStateVersion;
    keyboard = {
      layout = "us";
      variant = "intl";
      model = "pc105";
    };
    packages = with pkgs; [
      autenticacao-gov-pt
      arandr
      bash
      bash-language-server
      brightnessctl
      cabal-install
      cargo
      ccls
      cmake
      cmake-language-server
      discord
      drawio
      fd
      feh
      firefox
      fira-sans
      flameshot
      font-manager
      fzf
      gcc
      glibc
      glib
      gnumake
      i3
      inter
      iosevka
      jdk
      kitty
      libsForQt5.okular
      libnotify
      libreoffice
      libtool
      lua-language-server
      man-pages
      man-pages-posix
      markdown-oxide
      material-design-icons
      mattermost-desktop
      nerd-fonts.symbols-only
      nerd-fonts.iosevka
      networkmanagerapplet
      networkmanager-openvpn
      networkmanager-vpnc
      nil
      nodejs_24
      noisetorch
      noto-fonts
      obsidian
      openssl
      openvpn
      pavucontrol
      picom
      playerctl
      polybarFull
      pylyzer
      python311
      ranger
      ripgrep
      rofi
      rustc
      spotify
      stremio
      tdf
      texlab
      texliveFull
      thunderbird
      tmux
      typst
      usbutils
      vpnc
      xclip
      zathura
      zip
      zoom-us
      zotero
    ];
  };

  # Fonts
  fonts.fontconfig = {
    enable = true;
    defaultFonts = {
      monospace = [ "Iosevka" ];
      sansSerif = [ "Inter" ];
    };
  };

  # Fix for nerd-fonts
  home.file.".local/share/fonts/NerdFonts" = {
    source = "${pkgs.nerd-fonts.symbols-only}/share/fonts/truetype/NerdFonts/Symbols";
    recursive = true;
  };


  # Dotfiles
  home.file.".bashrc".source = ./.bashrc;
  home.file.".bash_profile".source = ./.bash_profile;
  home.file.".config" = {
    source = ./.config;
    recursive = true;
  };

  # Nvim
  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
  };

  programs.ssh = {
    enable = true;
    matchBlocks = {
      "cloud*" = {
        user = "gsd";
        hostname = "%h.cluster.lsd.di.uminho.pt";
        identityFile = "/home/${user}/.ssh/cloudinhas";
        forwardAgent = true;
      };
      "deucalion" = {
        user = "jose.p.peixoto";
        hostname = "login.deucalion.macc.fccn.pt";
        identityFile = "/home/${user}/.ssh/deucalion";
        forwardAgent = true;
      };
    };
  };

  # GUI settings
  gtk = {
    enable = true;
    gtk3.extraConfig.gtk-application-prefer-dark-theme = 1;
    theme.name = "Adwaita";
    iconTheme.name = "Adwaita";
  };

  # Git
  programs.git = {
    enable = true;
    userName = "vaavaav";
    userEmail = "the.jprp@gmail.com";
    extraConfig = {
      init.defaultBranch = "main";
    };
  };

  # i3
  xsession = {
    enable = true;
    windowManager.command = "i3";
  };

  # Blue filter
  services.sctd = {
    enable = true;
    baseTemperature = 3000;
  };

  # VPN 
  home.activation.createUminhoVPN = lib.hm.dag.entryAfter ["networking"] ''
  if ! ${pkgs.networkmanager}/bin/nmcli connection show "uminho-vpn" &>/dev/null; then
    echo "Creating 'uminho-vpn' connection via nmcli..."

    ${pkgs.networkmanager}/bin/nmcli connection add type vpn \
      con-name "uminho-vpn" \
      ifname -- \
      vpn-type vpnc \
      vpn.service-type org.freedesktop.NetworkManager.vpnc \
      vpn.data "IPSec gateway=vpn.uminho.pt,IPSec ID=geral,Xauth username=d14110@di.uminho.pt" \
      vpn.secrets "IPSec secret=geral"
  else
    echo "'uminho-vpn' connection already exists."
  fi
'';


  # tmux
  home.activation.installTPM = lib.hm.dag.entryAfter [ ]
    ''
      # Clone TPM if not already installed
      if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
        git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
      fi

      # Install tmux plugins
      if command -v tmux >/dev/null 2>&1; then
        tmux new-session -d -s plugin_installer "tmux source ~/.config/tmux.conf \; run-shell '~/.tmux/plugins/tpm/bindings/install_plugins' && exit"
      fi
    '';

  # Limiting number of generations
  home.activation.pruneOldGenerations = lib.hm.dag.entryAfter [ "nixos-rebuild" ]
    ''
      nix-env --delete-generations '+4'
    '';
}

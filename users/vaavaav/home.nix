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
      bat
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
      playerctl
      polybarFull
      pylyzer
      python311
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
      vagrant
      vpnc
      xclip
      zathura
      zip
      zoom-us
      zotero
      zoxide
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
    extraConfig.init.defaultBranch = "main";
  };

  # Blue filter
  services.sctd = {
    enable = true;
    baseTemperature = 3000;
  };

  # SSH
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

  # Tmux Plugin Manager
  home.file.".tmux/plugins/tpm".source = fetchGit {
    url = "https://github.com/tmux-plugins/tpm.git";
    rev = "99469c4a9b1ccf77fade25842dc7bafbc8ce9946"; 
  };

  # Limiting number of generations
  home.activation.pruneOldGenerations = lib.hm.dag.entryAfter [ "nixos-rebuild" ]
    ''
      nix-env --delete-generations '+4'
    '';

  # Nvim
  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
  };

  # Kitty
   programs.kitty = {
    enable = true;
    settings = {
      foreground = "#DCD7BA";
      background = "#1F1F28";
      color0  = "#16161D";
      color1  = "#C34043";
      color2  = "#98BB6C";
      color3  = "#DCA561";
      color4  = "#7E9CD8";
      color5  = "#957FB8";
      color6  = "#6A9589";
      color7  = "#DCD7BA";
      color8  = "#717C7C";
      color9  = "#E82424";
      color10 = "#76946A";
      color11 = "#FF9E3B";
      color12 = "#658594";
      color13 = "#938AA9";
      color14 = "#7AA89F";
      color15 = "#D27E99";
      selection_foreground = "#DCA561";
      selection_background = "#223249";
      font_size = 15;
      font_family = "Iosevka, Iosevka Regular, Monospace";
      bold_font = "Iosevka Bold";
      italic_font = "Iosevka Italic";
      bold_italic_font = "Iosevka Bold Italic";
      confirm_os_window_close = "0";
      enable_audio_bell = "no";
    };
  };

  # i3
  xsession = {
    enable = true;
    windowManager.command = "i3";
  };

  # Picom
  services.picom = {
    enable = true;
    fade = true;
    fadeSteps = [ 0.03 0.03 ];
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

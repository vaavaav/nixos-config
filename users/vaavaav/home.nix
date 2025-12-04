{
  pkgs,
  lib,
  ...
}:
let
  username = "vaavaav";
  homeDirectory = "/home/${username}";
  ghostscript-fonts = import ./../../flakes/ghostscript-fonts/default.nix { inherit pkgs lib; };
in
{
  nixpkgs.config.allowUnfree = true;

  home = {
    username = username;
    homeDirectory = homeDirectory;
    stateVersion = "25.11";
    keyboard = {
      layout = "us";
      variant = "intl";
      model = "pc105";
    };
    packages = with pkgs; [
      arandr
      asciinema
      asciinema-agg
      autenticacao-gov-pt-bin
      bash
      bash-language-server
      bat
      brightnessctl
      cabal-install
      cargo
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
      glib
      glibc
      gnumake
      ghostscript-fonts
      haskell-language-server
      i3
      i3status-rust
      inter
      iosevka
      jdk
      kitty
      libertinus
      libnotify
      libreoffice
      libtool
      ltex-ls
      lua-language-server
      man-pages
      man-pages-posix
      markdown-oxide
      material-design-icons
      mullvad-vpn
      nerd-fonts.iosevka
      nerd-fonts.symbols-only
      networkmanager-openvpn
      networkmanager-vpnc
      networkmanagerapplet
      nil
      nixfmt-rfc-style
      nodejs_24
      noto-fonts
      obsidian
      openssl
      openvpn
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
      usbutils
      vagrant
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
    settings = {
      user = {
        name = "vaavaav";
        email = "the.jprp@gmail.com";
      };
      init.defaultBranch = "main";
    };
  };

  # Blue filter
  #  services.sctd = {
  #    enable = true;
  #    baseTemperature = 3000;
  #  };

  # SSH
  services.ssh-agent.enable = true;
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks = {
      "*" = {
        forwardAgent = false;
        addKeysToAgent = "yes";
        compression = false;
        serverAliveInterval = 0;
        serverAliveCountMax = 3;
        hashKnownHosts = false;
        userKnownHostsFile = "~/.ssh/known_hosts";
        controlMaster = "no";
        controlPath = "~/.ssh/master-%r@%n:%p";
        controlPersist = "no";
      };
      "cloud*" = {
        user = "gsd";
        hostname = "%h.cluster.lsd.di.uminho.pt";
        identityFile = [
          "${homeDirectory}/.ssh/cloudinhas"
        ];
        forwardAgent = true; # Needed to use local ssh keys on remote host
        forwardX11 = true; # Needed to use clipboard over ssh and GUI apps
        forwardX11Trusted = true; # Needed to use clipboard over ssh and GUI apps
      };
      "deucalion" = {
        user = "jose.p.peixoto";
        hostname = "login.deucalion.macc.fccn.pt";
        identityFile = [
          "${homeDirectory}/.ssh/deucalion"
        ];
        forwardAgent = true; # Needed to use local ssh keys on remote host
        forwardX11 = true; # Needed to use clipboard over ssh and GUI apps
        forwardX11Trusted = true; # Needed to use clipboard over ssh and GUI apps
      };
    };
  };

  # VPN
  home.activation.createUminhoVPN = lib.hm.dag.entryAfter [ "networking" ] ''
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
  home.activation.pruneOldGenerations = lib.hm.dag.entryAfter [ "nixos-rebuild" ] ''
    nix-env --delete-generations '+4'
  '';

  # Nvim
  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
  };

  programs.kitty = {
    enable = true;
    settings = {
      background = "#1F1F28";
      foreground = "#DCD7BA";

      color0 = "#16161D";
      color1 = "#C34043";
      color2 = "#76946A";
      color3 = "#C0A36E";
      color4 = "#7E9CD8";
      color5 = "#957FB8";
      color6 = "#6A9589";
      color7 = "#C8C093";

      color8 = "#727169";
      color9 = "#E82424";
      color10 = "#98BB6C";
      color11 = "#E6C384";
      color12 = "#7FB4CA";
      color13 = "#938AA9";
      color14 = "#7AA89F";
      color15 = "#DCD7BA";

      # extended colors
      color16 = "#FFA066";
      color17 = "#FF5D62";

      selection_foreground = "#C8C093";
      selection_background = "#2D4F67";

      url_color = "#72A7BC";
      cursor = "#C8C093";

      # Padding
      window_padding_width = 4;

      # Tabs
      active_tab_background = "#1F1F28";
      active_tab_foreground = "#C8C093";
      inactive_tab_background = "#1F1F28";
      inactive_tab_foreground = "#727169";
      # tab_bar_background = "#15161E";

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

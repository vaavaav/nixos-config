{ homeStateVersion, user, pkgs, lib, autenticacao-gov-pt, ... }:
let terminal = pkgs.kitty;
in 
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
      terminal
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

  # Tmux
  programs.tmux = {
    enable = true;
    mouse = true;
    terminal = "screen-256color";  
    baseIndex = 1;
    keyMode = "vi";
    sensibleOnTop = true;
    plugins = with pkgs; [
      tmuxPlugins.yank
      {
        plugin = tmuxPlugins.kanagawa;
        extraConfig = ''
          set -g @kanagawa-theme 'wave'
          set -g @kanagawa-show-flags true
          set -g @kanagawa-show-empty-plugins false
          set -g @kanagawa-plugins "ssh-session time"
          set -g @kanagawa-ssh-session-colors "light_purple white"
          set -g @kanagawa-time-colors "dark_purple white"
          set -g @kanagawa-time-format "%A %d/%m %I:%M %p"
          set -g @kanagawa-git-show-remote-status true
          '';
      }
    ];
    extraConfig = ''
      set -g update-environment "SSH_ASKPASS SSH_AUTH_SOCK SSH_AGENT_PID SSH_CONNECTION"

      set-option -g renumber-windows on

      bind -n C-M-h previous-window
      bind -n C-M-l next-window

      set -g @plugin 'aserowy/tmux.nvim'
      set -g @tmux-nvim-resize-step-x 5
      set -g @tmux-nvim-resize-step-y 5

      bind-key -T copy-mode-vi v send-keys -X begin-selection
      bind-key -T copy-mode-vi C-v send-keys -X rectangle-toggle
      bind-key -T copy-mode-vi y send-keys -X copy-selection-and-cancel

      bind ";" split-window -h -c "#{pane_current_path}"
      bind "/" split-window -v -c "#{pane_current_path}"
    '';
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
      "95:class_g = '${terminal.pname}' && focused"
      "90:class_g = '${terminal.pname}' && !focused"
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
        "window_type = 'desktop' && class_g != '${terminal.pname}'"
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

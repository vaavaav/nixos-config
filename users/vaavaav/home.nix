{ homeStateVersion, user, pkgs, lib, ... }:
{

  nixpkgs.config.allowUnfree = true;

  home = {
    username = user;
    homeDirectory = "/home/${user}";
    sessionVariables = {
      NIX_SHELL_PRESERVE_PROMPT = 1;
    };
    stateVersion = homeStateVersion;
    keyboard = {
      layout = "us";
      variant = "intl";
      model = "pc105";
    };
    packages = with pkgs; [
      alacritty
      arandr
      bash
      brightnessctl
      cabal-install
      cargo
      clang_12
      cmake
      discord
      drawio
      feh
      firefox
      flameshot
      font-manager
      fzf
      gcc-unwrapped
      gnumake
      i3
      inter
      iosevka
      jdk
      libreoffice
      material-design-icons
      nerdfonts
      networkmanager-openvpn
      networkmanagerapplet
      nodejs_23
      noisetorch
      noto-fonts
      openssl
      openvpn
      pavucontrol
      picom
      playerctl
      polybarFull
      python311
      rofi
      rustc
      spotify
      stow
      stremio
      thunderbird
      texliveFull
      tmux
      typst
      usbutils
      whatsapp-for-linux
      xclip
      zathura
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

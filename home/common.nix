{ netDevice, displayConfig }:
{
  pkgs,
  lib,
  config,
  hostname,
  ...
}:
let
  username = "zezocas";
  homeDirectory = "/home/${username}";
  ghostscript-fonts = import ../flakes/ghostscript-fonts/default.nix { inherit pkgs lib; };
in
{
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

  # Dotfiles (raw, untouched)
  home.file.".bashrc".source = ./dotfiles/.bashrc;
  home.file.".bash_profile".source = ./dotfiles/.bash_profile;
  home.file.".config" = {
    source = ./dotfiles/.config;
    recursive = true;
  };

  xdg.configFile."i3/config".text = ''
    font pango:Iosevka 12
    set $mod Mod4
    set $wm_setting_key_left h
    set $wm_setting_key_right l
    set $wm_setting_key_up k
    set $wm_setting_key_down j

    set $wallpaper feh --bg-fill --randomize ~/.wallpapers

    # Applications
    bindsym $mod+Return exec kitty
    bindsym $mod+d exec rofi -show drun -icon-theme \"Papirus\" -show-icons 
    bindsym $mod+b exec $wallpaper
    bindsym $mod+Shift+s exec flameshot gui
    bindsym $mod+t exec picom-trans -c -t

    exec --no-startup-id picom
    exec --no-startup-id $wallpaper

    # Bar
    bindsym $mod+m bar mode toggle
    bar {
        status_command    i3status-rs ~/.config/i3status-rust/config.toml
        position          top
        mode              dock
        workspace_buttons yes
        tray_output       none
    }

    # Gaps
    gaps inner 6
    gaps outer 3

    # Borders
    default_border none
    floating_modifier $mod

    # switch to workspace
    bindsym $mod+1 workspace $ws1
    bindsym $mod+2 workspace $ws2
    bindsym $mod+3 workspace $ws3
    bindsym $mod+4 workspace $ws4
    bindsym $mod+5 workspace $ws5
    bindsym $mod+6 workspace $ws6
    bindsym $mod+7 workspace $ws7
    bindsym $mod+8 workspace $ws8
    bindsym $mod+9 workspace $ws9
    bindsym $mod+0 workspace $ws10

    # move focused container to workspace
    bindsym $mod+Shift+1 move container to workspace $ws1
    bindsym $mod+Shift+2 move container to workspace $ws2
    bindsym $mod+Shift+3 move container to workspace $ws3
    bindsym $mod+Shift+4 move container to workspace $ws4
    bindsym $mod+Shift+5 move container to workspace $ws5
    bindsym $mod+Shift+6 move container to workspace $ws6
    bindsym $mod+Shift+7 move container to workspace $ws7
    bindsym $mod+Shift+8 move container to workspace $ws8
    bindsym $mod+Shift+9 move container to workspace $ws9
    bindsym $mod+Shift+0 move container to workspace $ws10

    set $ws1  "1"
    set $ws2  "2"
    set $ws3  "3"
    set $ws4  "4"
    set $ws5  "5"
    set $ws6  "6"
    set $ws7  "7"
    set $ws8  "8"
    set $ws9  "9"
    set $ws10 "10"

    # kill focused window
    bindsym $mod+Shift+q kill

    # restart i3 inplace (preserves your layout/session, can be used to update i3)
    bindsym $mod+Shift+r restart

    # Backlight control
    bindsym XF86MonBrightnessUp   exec brightnessctl set +10%
    bindsym XF86MonBrightnessDown exec brightnessctl set 10%-
    bindsym $mod+F5 exec brightnessctl set 10%-
    bindsym $mod+F6 exec brightnessctl set +10%

    # change focus
    bindsym $mod+$wm_setting_key_left  focus left
    bindsym $mod+$wm_setting_key_down  focus down
    bindsym $mod+$wm_setting_key_up    focus up
    bindsym $mod+$wm_setting_key_right focus right

    # move focused window
    bindsym $mod+Shift+$wm_setting_key_left  move left
    bindsym $mod+Shift+$wm_setting_key_down  move down
    bindsym $mod+Shift+$wm_setting_key_up    move up
    bindsym $mod+Shift+$wm_setting_key_right move right

    # Resize
    mode "resize" {
      bindsym $wm_setting_key_left  resize shrink width 5 px or 5 ppt
      bindsym $wm_setting_key_down  resize shrink height 5 px or 5 ppt
      bindsym $wm_setting_key_up    resize grow   height 5 px or 5 ppt
      bindsym $wm_setting_key_right resize grow   width  5 px or 5 ppt
      bindsym Return mode "default"
      bindsym Escape mode "default"
    }
    bindsym $mod+r mode "resize"

    # split in horizontal orientation
    bindsym $mod+Ctrl+h split h

    # split in vertical orientation
    bindsym $mod+Ctrl+v split v

    # enter fullscreen mode for the focused container
    bindsym $mod+f fullscreen toggle

    # change container layout (stacked, tabbed, toggle split)
    bindsym $mod+s layout stacking
    bindsym $mod+g layout tabbed
    bindsym $mod+e layout toggle split

    # toggle tiling / floating
    bindsym $mod+Shift+space floating toggle

    # change focus between tiling / floating windows
    bindsym $mod+space focus mode_toggle

    # sound
    bindsym XF86AudioMute exec "pactl set-sink-mute @DEFAULT_SINK@ toggle"
    bindsym XF86AudioLowerVolume exec "pactl set-sink-volume @DEFAULT_SINK@ -5%"
    bindsym XF86AudioRaiseVolume exec "pactl set-sink-volume @DEFAULT_SINK@ +5%"
    bindsym XF86AudioMicMute exec "pactl set-source-mute @DEFAULT_SOURCE@ toggle"
    bindsym $mod+F1 exec "pactl set-sink-mute @DEFAULT_SINK@ toggle"
    bindsym $mod+F2 exec "pactl set-sink-volume @DEFAULT_SINK@ -5%"
    bindsym $mod+F3 exec "pactl set-sink-volume @DEFAULT_SINK@ +5%"
    bindsym $mod+F4 exec "pactl set-source-mute @DEFAULT_SOURCE@ toggle"

    # music
    bindsym XF86AudioPlay exec "playerctl --player=spotify play-pause"
    bindsym XF86AudioPrev exec "playerctl --player=spotify previous"
    bindsym XF86AudioNext exec "playerctl --player=spotify next"
    bindsym $mod+p       exec "playerctl --player=spotify play-pause"
    bindsym $mod+bracketleft  exec "playerctl --player=spotify previous"
    bindsym $mod+bracketright exec "playerctl --player=spotify next"

    # display
    ${displayConfig}

    # Window Border and Title Bar Colors 
    client.focused          #2d4f67  #2d4f67  #dcd7ba  #7fb4ca  #2d4f67
    client.focused_inactive #223249  #223249  #c8c093  #3e4c66  #223249
    client.unfocused        #1f1f28  #1f1f28  #727169  #3a3d4d  #1f1f28
    client.urgent           #e82424  #e82424  #dcd7ba  #e82424  #e82424
    client.placeholder      #1f1f28  #1f1f28  #c8c093  #1f1f28  #1f1f28

    client.background       #1f1f28

    # Float zoom pop-up windows
    for_window [title="^zoom$" class="[zoom]*"] floating enable
  '';

  # i3status-rust
  xdg.configFile."i3status-rust/config.toml".text = ''
    # i3status-rust configuration file
    # Kanagawa theme 
    [theme]
    theme = "plain"
    [icons]
    icons = "none"
    [theme.overrides]
    separator = " | "
    idle_bg = "#1F1F28"
    idle_fg = "#DCD7BA"
    info_bg = "#1F1F28"
    info_fg = "#7E9CD8"
    good_bg = "#1F1F28"
    good_fg = "#76946A"
    warning_bg = "#1F1F28"
    warning_fg = "#C0A36E"
    critical_bg = "#1F1F28"
    critical_fg = "#C34043"
    [[block]]
    block = "custom"
    format = "{ $text.str(max_w:45,rot_interval:0.5,rot_separator:' ~ ') |}"
    hide_when_empty = true
    interval = 1
    json = true
    command = ''''
    PLAYER="spotify"
    status=$(playerctl -p $PLAYER status 2>/dev/null | sed 's/"/\\\"/g')
    artist=$(playerctl -p $PLAYER metadata artist 2>/dev/null | sed 's/"/\\\"/g')
    title=$(playerctl -p $PLAYER metadata title 2>/dev/null | sed 's/"/\\\"/g')
    text="$title"
    if [[ -n "$artist" ]]; then
        text="$artist - $title"
    else 
        album=$(playerctl -p $PLAYER metadata album 2>/dev/null)
        if [[ -n "$album" ]]; then
            text="$album - $title"
        fi
    fi
    state="idle"
    if [[ "$status" == "Playing" ]]; then
        state="info"
    fi
    echo "{\"text\":\"$text\",\"state\":\"$state\"}"
    ''''
    click = [
      {button = "left", cmd = "bash -c 'playerctl metadata url 2>/dev/null | xclipboard -selection clipboard'"}
    ]
    [[block]]
    block = "time"
    interval = 60
    # time block uses strftime-style format strings
    format = " $timestamp.datetime(f:'(%H:%M) %a, %d-%m') "
    [[block]]
    block = "net"
    device = "${netDevice}"
    format = " {$ssid [$frequency.eng(w:0)] ($speed_down.eng(w:0, unit:b) \\| $speed_up.eng(w:0, unit:b))| Wired connection} "
    inactive_format = " No network "
    missing_format = " Unknown net interface "
    [block.theme_overrides]
    idle_fg = "#76946A"
    critical_fg = "#C34043"
    [[block]]
    block = "sound"
    format = " {Vol $volume.eng(w:0)|muted} "
    max_vol=150
    [[block.click]]
    button = "left"
    action = "toggle_mute"
    [block.theme_overrides]
    idle_fg = "#C0A36E"
    critical_fg = "#C34043"
    [[block]]
    block = "cpu"
    interval = 1
    format = " CPU $utilization.eng(w:0) "
    format_alt = " CPU $utilization.eng(w:0) $frequency.eng(w:0) "
    [block.theme_overrides]
    idle_fg = "#7E9CD8"
    warning_fg = "#C0A36E"
    critical_fg = "#C34043"
    [[block]]
    block = "memory"
    format = " Mem $mem_used_percents.eng(w:0) "
    format_alt = " Mem $mem_used.eng(w:0)/$mem_total.eng(w:0) "
    warning_mem = 80
    critical_mem = 90
    [block.theme_overrides]
    idle_fg = "#938AA9"
    warning_fg = "#C0A36E"
    critical_fg = "#C34043"
    [[block]]
    block = "disk_space"
    alert = 85.0
    warning = 90.0
    info_type = "used"
    format = " $icon $percentage.eng(w:0) "
    format_alt = " $icon $used.eng(w:0) / $total.eng(w:0) "
    [[block]]
    block = "battery"
    format = " $icon $percentage "
    full_format = " $icon $percentage "
  '';

  # GUI settings
  gtk = {
    enable = true;
    gtk3.extraConfig.gtk-application-prefer-dark-theme = 1;
    gtk4.theme = config.gtk.theme;
    theme.name = "Adwaita";
    iconTheme.name = "Adwaita";
  };

  # Git
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "zezocas";
        email = "the.jprp@gmail.com";
      };
      init.defaultBranch = "main";
    };
  };

  # SSH
  services.ssh-agent.enable = true;
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = {
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
        identityFile = [ "${homeDirectory}/.ssh/cloudinhas" ];
        forwardAgent = true;
        forwardX11 = true;
        forwardX11Trusted = true;
      };
      "deucalion" = {
        user = "jose.p.peixoto";
        hostname = "login.deucalion.macc.fccn.pt";
        identityFile = [ "${homeDirectory}/.ssh/deucalion" ];
        forwardAgent = true;
        forwardX11 = true;
        forwardX11Trusted = true;
      };
      "frontera" = {
        user = "jppeixoto";
        hostname = "frontera.tacc.utexas.edu";
        identityFile = [ "${homeDirectory}/.ssh/tacc" ];
        forwardAgent = true;
        forwardX11 = true;
        forwardX11Trusted = true;
      };
      "vista" = {
        user = "jppeixoto";
        hostname = "vista.tacc.utexas.edu";
        identityFile = [ "${homeDirectory}/.ssh/tacc" ];
        forwardAgent = true;
        forwardX11 = true;
        forwardX11Trusted = true;
      };
      "taiwania" = {
        user = "jose.p.peixoto";
        hostname = "140.110.109.147";
        identityFile = [ "${homeDirectory}/.ssh/taiwania" ];
        forwardAgent = true;
        forwardX11 = true;
        forwardX11Trusted = true;
      };
    };
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
    withRuby = false;
    withPython3 = false;
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
      color16 = "#FFA066";
      color17 = "#FF5D62";
      selection_foreground = "#C8C093";
      selection_background = "#2D4F67";
      url_color = "#72A7BC";
      cursor = "#C8C093";
      window_padding_width = 4;
      active_tab_background = "#1F1F28";
      active_tab_foreground = "#C8C093";
      inactive_tab_background = "#1F1F28";
      inactive_tab_foreground = "#727169";
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

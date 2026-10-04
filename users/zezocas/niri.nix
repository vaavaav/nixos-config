{ pkgs, ... }:
let
  random-wallpaper = pkgs.writeShellScriptBin "random-wallpaper" ''
    img=$(find ~/.wallpapers -type f | shuf -n 1)
    pkill -x swaybg
    exec swaybg -m fill -i "$img"
  '';

  fuzzel-run = pkgs.writeShellScriptBin "fuzzel-run" ''
    cmd=$(compgen -c | sort -u | fuzzel --dmenu --prompt "run  ") || exit 0
    exec setsid -f bash -c "$cmd"
  '';

  flameshotDialogs = "^(Save screenshot|Save Error|Quit Capture|Configuration|Hot Keys|Open With|flameshot-pin)$";
in
{
  home.packages = with pkgs; [
    swaybg
    wl-clipboard
    xwayland-satellite
    playerctl
    random-wallpaper
    fuzzel-run
  ];

  xdg.configFile."niri/config.kdl".text = ''
    input {
        keyboard {
            xkb {
                layout "us"
                variant "intl"
            }
        }
        touchpad {
            tap
            natural-scroll
        }
    }

    layout {
        gaps 6
        struts {
            left 3
            right 3
            top 3
            bottom 3
        }
        default-column-width { proportion 1.0; }
        preset-column-widths {
            proportion 0.33333
            proportion 0.5
            proportion 0.66667
            proportion 1.0
        }
        focus-ring { off; }
        tab-indicator {
            active-color "#7fb4ca"
            inactive-color "#3e4c66"
        }
        background-color "transparent"
    }

    prefer-no-csd
    hotkey-overlay { skip-at-startup; }
    screenshot-path "~/Pictures/Screenshots/%Y-%m-%d_%H-%M-%S.png"

    environment {
        NIXOS_OZONE_WL "1"
    }

    cursor {
        xcursor-theme "Bibata-Modern-Classic"
        xcursor-size 24
    }

    blur {
        passes 2
        offset 3
    }

    spawn-at-startup "waybar"
    spawn-at-startup "random-wallpaper"

    layer-rule {
        match namespace="^wallpaper$"
        place-within-backdrop true
    }

    layer-rule {
        match namespace="^(waybar|launcher|notifications)$"
        geometry-corner-radius 12
        background-effect { blur true; }
    }

    window-rule {
        open-maximized-to-edges false
    }

    window-rule {
        match app-id="^kitty$"
        opacity 0.90
        draw-border-with-background false
        background-effect { blur true; }
    }

    window-rule {
        match app-id="^kitty$" is-focused=true
        opacity 0.95
    }

    window-rule {
        match app-id="^thunderbird$"
        match app-id="^zoom" title="^zoom$"
        match app-id="firefox$" title="^Picture-in-Picture$"
        match app-id="flameshot" title="${flameshotDialogs}"
        exclude app-id="^thunderbird$" title="Thunderbird$"
        open-floating true
    }

    window-rule {
        match app-id="flameshot"
        exclude title="${flameshotDialogs}"
        open-fullscreen true
    }

    binds {
        Mod+Shift+Slash { show-hotkey-overlay; }

        Mod+Return { spawn "kitty"; }
        Mod+D { spawn "fuzzel"; }
        Mod+Shift+D { spawn "fuzzel-run"; }
        Mod+B { spawn "random-wallpaper"; }
        Mod+Shift+S { spawn "flameshot" "gui"; }
        Print { spawn "flameshot" "gui"; }
        Mod+T { toggle-window-rule-opacity; }
        Mod+M { spawn-sh "pkill -USR1 -x waybar"; }
        Mod+O repeat=false { toggle-overview; }
        Mod+Shift+Q repeat=false { close-window; }
        Mod+Shift+E { quit; }
        Mod+Escape allow-inhibiting=false { toggle-keyboard-shortcuts-inhibit; }

        Mod+H { focus-column-or-monitor-left; }
        Mod+L { focus-column-or-monitor-right; }
        Mod+J { focus-window-or-workspace-down; }
        Mod+K { focus-window-or-workspace-up; }
        Mod+Left { focus-column-or-monitor-left; }
        Mod+Right { focus-column-or-monitor-right; }
        Mod+Down { focus-window-or-workspace-down; }
        Mod+Up { focus-window-or-workspace-up; }

        Mod+Shift+H { move-column-left-or-to-monitor-left; }
        Mod+Shift+L { move-column-right-or-to-monitor-right; }
        Mod+Shift+J { move-window-down-or-to-workspace-down; }
        Mod+Shift+K { move-window-up-or-to-workspace-up; }

        Mod+N { focus-monitor-next; }
        Mod+Shift+N { move-column-to-monitor-next; }

        Mod+Ctrl+H { set-column-width "-5%"; }
        Mod+Ctrl+L { set-column-width "+5%"; }
        Mod+Ctrl+J { set-window-height "-5%"; }
        Mod+Ctrl+K { set-window-height "+5%"; }
        Mod+R { switch-preset-column-width; }
        Mod+Shift+R { switch-preset-column-width-back; }
        Mod+Ctrl+R { reset-window-height; }

        Mod+Comma { consume-or-expel-window-left; }
        Mod+Period { consume-or-expel-window-right; }
        Mod+C { center-column; }
        Mod+E { expand-column-to-available-width; }
        Mod+G { toggle-column-tabbed-display; }
        Mod+S { toggle-column-tabbed-display; }
        Mod+F { fullscreen-window; }
        Mod+Shift+F { maximize-column; }
        Mod+Shift+Space { toggle-window-floating; }
        Mod+Space { switch-focus-between-floating-and-tiling; }

        Mod+1 { focus-workspace 1; }
        Mod+2 { focus-workspace 2; }
        Mod+3 { focus-workspace 3; }
        Mod+4 { focus-workspace 4; }
        Mod+5 { focus-workspace 5; }
        Mod+6 { focus-workspace 6; }
        Mod+7 { focus-workspace 7; }
        Mod+8 { focus-workspace 8; }
        Mod+9 { focus-workspace 9; }
        Mod+0 { focus-workspace 10; }
        Mod+Shift+1 { move-column-to-workspace 1; }
        Mod+Shift+2 { move-column-to-workspace 2; }
        Mod+Shift+3 { move-column-to-workspace 3; }
        Mod+Shift+4 { move-column-to-workspace 4; }
        Mod+Shift+5 { move-column-to-workspace 5; }
        Mod+Shift+6 { move-column-to-workspace 6; }
        Mod+Shift+7 { move-column-to-workspace 7; }
        Mod+Shift+8 { move-column-to-workspace 8; }
        Mod+Shift+9 { move-column-to-workspace 9; }
        Mod+Shift+0 { move-column-to-workspace 10; }
        Mod+WheelScrollDown cooldown-ms=150 { focus-workspace-down; }
        Mod+WheelScrollUp cooldown-ms=150 { focus-workspace-up; }

        XF86MonBrightnessUp allow-when-locked=true { spawn-sh "brightnessctl set +10%"; }
        XF86MonBrightnessDown allow-when-locked=true { spawn-sh "brightnessctl set 10%-"; }
        Mod+F6 { spawn-sh "brightnessctl set +10%"; }
        Mod+F5 { spawn-sh "brightnessctl set 10%-"; }

        XF86AudioMute allow-when-locked=true { spawn-sh "pactl set-sink-mute @DEFAULT_SINK@ toggle"; }
        XF86AudioLowerVolume allow-when-locked=true { spawn-sh "pactl set-sink-volume @DEFAULT_SINK@ -5%"; }
        XF86AudioRaiseVolume allow-when-locked=true { spawn-sh "pactl set-sink-volume @DEFAULT_SINK@ +5%"; }
        XF86AudioMicMute allow-when-locked=true { spawn-sh "pactl set-source-mute @DEFAULT_SOURCE@ toggle"; }
        Mod+F1 { spawn-sh "pactl set-sink-mute @DEFAULT_SINK@ toggle"; }
        Mod+F2 { spawn-sh "pactl set-sink-volume @DEFAULT_SINK@ -5%"; }
        Mod+F3 { spawn-sh "pactl set-sink-volume @DEFAULT_SINK@ +5%"; }
        Mod+F4 { spawn-sh "pactl set-source-mute @DEFAULT_SOURCE@ toggle"; }

        XF86AudioPlay allow-when-locked=true { spawn-sh "playerctl -p spotify play-pause"; }
        XF86AudioPrev allow-when-locked=true { spawn-sh "playerctl -p spotify previous"; }
        XF86AudioNext allow-when-locked=true { spawn-sh "playerctl -p spotify next"; }
        Mod+P { spawn-sh "playerctl -p spotify play-pause"; }
        Mod+BracketLeft { spawn-sh "playerctl -p spotify previous"; }
        Mod+BracketRight { spawn-sh "playerctl -p spotify next"; }
    }
  '';
}

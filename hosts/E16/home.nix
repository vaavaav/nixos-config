import ../../home/common.nix {
  netDevice = "wlp2s0";
  displayConfig = ''
    set $display_cmd (( xrandr | grep -q 'DP-1 connected' ) && (xrandr --output eDP-1 --primary --mode 1920x1200 --pos 2560x240 --rotate normal --output DP-1 --mode 2560x1440 --pos 0x0 --rotate normal) || ( xrandr --output eDP-1 --primary --mode 1920x1200 --pos 320x1440 --rotate normal --output DP-1 --off)) && $wallpaper
    bindsym $mod+F7     exec $display_cmd
    bindsym XF86Display exec $display_cmd
  '';
}

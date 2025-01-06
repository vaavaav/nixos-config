import ../../home/common.nix {
  netDevice = "wlp1s0f0u2";
  displayConfig = ''
    set $display_cmd $wallpaper
    bindsym $mod+F7     exec $display_cmd
    bindsym XF86Display exec $display_cmd
  '';
}

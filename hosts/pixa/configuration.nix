{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/wifi-dongle.nix
  ];

  # Passed through to the home-manager config (i3 / status bar).
  home-manager.extraSpecialArgs = {
    netDevice = "wlp1s0f0u2";
    displayConfig = ''
      set $display_cmd $wallpaper
      bindsym $mod+F7     exec $display_cmd
      bindsym XF86Display exec $display_cmd
    '';
  };
}

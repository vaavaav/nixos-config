{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/bluetooth.nix
    ../../modules/docker.nix
  ];

  # VPN
  services.mullvad-vpn.enable = true;

  # Passed through to the home-manager config (i3 / status bar).
  home-manager.extraSpecialArgs = {
    netDevice = "";
    displayConfig = ''
      set $display_cmd $wallpaper
      bindsym $mod+F7     exec $display_cmd
      bindsym XF86Display exec $display_cmd
    '';
  };
}

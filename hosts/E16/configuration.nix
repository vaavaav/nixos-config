{ pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/bluetooth.nix
    ../../modules/docker.nix
  ];

  # Printing
  environment.systemPackages = with pkgs; [ hplipWithPlugin ];
  services.printing = {
    enable = true;
    drivers = with pkgs; [ hplipWithPlugin ];
  };
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };
  programs.system-config-printer.enable = true;

  # VPN
  services.mullvad-vpn.enable = true;

  # Tailscale
  services.tailscale.enable = true;

  # Steam
  programs.steam = {
    enable = true;
    extraCompatPackages = [ pkgs.proton-ge-bin ];
  };

  # Passed through to the home-manager config (i3 / status bar).
  home-manager.extraSpecialArgs = {
    netDevice = "wlp2s0";
    displayConfig = ''
      set $display_cmd (( xrandr | grep -q 'DP-1 connected' ) && (xrandr --output eDP-1 --primary --mode 1920x1200 --pos 2560x240 --rotate normal --output DP-1 --mode 2560x1440 --pos 0x0 --rotate normal) || ( xrandr --output eDP-1 --primary --mode 1920x1200 --pos 320x1440 --rotate normal --output DP-1 --off)) && $wallpaper
      bindsym $mod+F7     exec $display_cmd
      bindsym XF86Display exec $display_cmd
    '';
  };
}

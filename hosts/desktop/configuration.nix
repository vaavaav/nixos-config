{
  pkgs,
  ...
}:
let
  hostname = "desktop";
in
{
  imports = [
    ./hardware-configuration.nix
  ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  environment.variables = {
    ETH_INTERFACE = "";
    WLAN_INTERFACE = "";
  };

  # Boot
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "nodev";
  boot.loader.useOSProber = true;
  time.hardwareClockInLocalTime = true;

  # System packages
  nixpkgs.config.allowUnfree = true;

  # System packages
  environment.systemPackages = with pkgs; [
    home-manager
    lightdm
    lightdm-gtk-greeter
    linuxHeaders
    man
    neofetch
    networkmanager
    unzip
    vim
    wget
    pulseaudioFull
    xorg.xorgserver
    xorg.xinit
    xorg.xwininfo
    git
    tmux
    vim
    nano
  ];

  # System configuration
  time.timeZone = "Europe/Lisbon";

  # Networking
  networking.hostName = hostname;
  networking.networkmanager.enable = true;
  networking.networkmanager.plugins = with pkgs; [
    networkmanager-vpnc
  ];

  # Sound
  services.pipewire = {
    enable = true;
    pulse.enable = true;
  };

  # Users
  users = {
    defaultUserShell = pkgs.bash;
    users."vaavaav" = {
      isNormalUser = true;
      extraGroups = [
        "wheel"
        "networkmanager"
        "lp"
      ];
    };
  };

  # Display and window manager
  services.displayManager.defaultSession = "xterm";
  services.xserver = {
    enable = true;
    desktopManager.xterm.enable = true;
    displayManager.lightdm.enable = true;
  };

  # SSH
  programs.ssh.askPassword = "";

  # System fonts
  fonts = {
    packages = with pkgs; [
      inter
    ];
    fontconfig.defaultFonts = {
      sansSerif = [ "Inter" ];
    };
  };

  # GUI settings
  programs.dconf.enable = true;
}

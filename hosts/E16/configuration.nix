{
  pkgs,
  ...
}:
let
  hostname = "E16";
in
{
  imports = [
    ./hardware-configuration.nix
  ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Boot
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 3;

  # System packages
  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [
    bluez
    bluez-tools
    git
    home-manager
    hplipWithPlugin
    lightdm
    lightdm-gtk-greeter
    linuxHeaders
    man
    nano
    neofetch
    networkmanager
    pulseaudioFull
    tmux
    unzip
    vim
    vim
    wget
    xorg.xinit
    xorg.xorgserver
    xorg.xwininfo
  ];

  # System configuration
  time.timeZone = "Europe/Lisbon";

  # Networking
  networking = {
    hostName = hostname;
    networkmanager.enable = true;
    networkmanager.plugins = with pkgs; [
      networkmanager-vpnc
    ];
  };

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

  environment.variables = {
    ETH_INTERFACE = "enp1s0";
    WLAN_INTERFACE = "wlp2s0";
  };

  # Docker
  virtualisation.docker = {
    rootless = {
      enable = true;
      setSocketVariable = true;
    };
  };

  # Bluetooth
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Enable = "Source,Sink,Media,Socket";
      };
    };
  };
  services.blueman.enable = true;

  # Printing
  services = {
    printing = {
      enable = true;
      drivers = with pkgs; [
        hplipWithPlugin
      ];
    };
    avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };
  };

  # Printing
  programs.system-config-printer.enable = true;

  # VPN
  services.mullvad-vpn.enable = true;
}

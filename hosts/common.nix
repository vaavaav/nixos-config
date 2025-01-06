{ pkgs, ... }:

{
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Boot
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 3;

  # Suppress the usual boot text log so the photo isn't interrupted by scrolling
  # kernel/systemd messages. Remove this block if you'd rather keep the logs.
  boot.consoleLogLevel = 3;
  boot.initrd.verbose = false;
  boot.kernelParams = [
    "quiet"
    "udev.log_level=3"
    "systemd.show_status=auto"
  ];

  # Nixpkgs
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.permittedInsecurePackages = [
    "electron-39.8.10"
  ];

  # Do not change this after initial install - see the NixOS manual entry
  # for system.stateVersion. It should match whatever release you first
  # installed with, not your current NixOS version.
  system.stateVersion = "25.11";

  # System packages (common to every host)
  environment.systemPackages = with pkgs; [
    brightnessctl
    fastfetch
    git
    home-manager
    lightdm
    lightdm-gtk-greeter
    linuxHeaders
    man
    man-pages
    man-pages-posix
    nano
    networkmanager
    pulseaudioFull
    unzip
    usbutils
    vim
    wget
    xinit
    xorg-server
    xwininfo
  ];

  # brightnessctl needs its udev rule installed to grant the `video` group
  # write access to the backlight, otherwise it silently requires sudo
  services.udev.packages = with pkgs; [
    brightnessctl
  ];

  # System configuration
  time.timeZone = "Europe/Lisbon";

  # Networking
  networking.networkmanager.enable = true;

  # Sound
  services.pipewire = {
    enable = true;
    pulse.enable = true;
  };

  # Users
  users = {
    defaultUserShell = pkgs.bash;
    users."zezocas" = {
      isNormalUser = true;
      extraGroups = [
        "wheel"
        "networkmanager"
        "lp"
        "video"
      ];
    };
  };

  # Display and window manager
  services.displayManager.defaultSession = "xterm";
  services.xserver = {
    enable = true;
    desktopManager.xterm.enable = true;
    displayManager.lightdm = {
      enable = true;
      background = ./../assets/background.png;
      greeters.gtk.extraConfig = ''
        font-name = Inter 11
      '';
    };
  };

  # SSH
  programs.ssh = {
    askPassword = "";
    startAgent = true;
  };

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

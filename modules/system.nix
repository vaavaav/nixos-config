{
  pkgs,
  hostname,
  ...
}:

{
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Boot
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 3;
  boot.loader.efi.canTouchEfiVariables = true;

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
  ];

  # brightnessctl needs its udev rule installed to grant the `video` group
  # write access to the backlight, otherwise it silently requires sudo
  services.udev.packages = with pkgs; [
    brightnessctl
  ];

  # System configuration
  time.timeZone = "Europe/Lisbon";

  # Networking (hostName comes from the flake, the single source of truth)
  networking.hostName = hostname;
  networking.networkmanager = {
    enable = true;
    plugins = with pkgs; [
      networkmanager-vpnc
      networkmanager-openvpn
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

  # Compositor
  programs.niri = {
    enable = true;
  };
  services.gnome.gcr-ssh-agent.enable = false;

  services.greetd = {
    enable = true;
    useTextGreeter = true;
    settings.default_session.command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd niri-session";
  };

  # SSH
  programs.ssh = {
    askPassword = "";
    startAgent = true;
  };

  # System fonts
  fonts = {
    packages = with pkgs; [
      geist-font
    ];
    fontconfig.defaultFonts = {
      sansSerif = [ "Geist" ];
    };
  };

  # GUI settings
  programs.dconf.enable = true;
}

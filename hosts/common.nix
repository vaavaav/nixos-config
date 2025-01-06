{ pkgs, stateVersion, hostname, user, ... }:
{

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # System packages
  environment.systemPackages = with pkgs; [
    home-manager
    bash
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
  system.stateVersion = stateVersion;
  time.timeZone = "Europe/Lisbon";

  # Networking
  networking.hostName = hostname;
  networking.networkmanager.enable = true;

  # Sound
  hardware.pulseaudio = {
    enable = true;
    package = pkgs.pulseaudioFull;
  };
  services.pipewire.enable = false;

  # Users
  users = {
    defaultUserShell = pkgs.bash;
    users.${user} = {
      isNormalUser = true;
      extraGroups = [ "wheel" "networkmanager" ];
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

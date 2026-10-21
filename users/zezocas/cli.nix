{ pkgs, lib, ... }:
{
  imports = [
    ./bash.nix
    ./git.nix
    ./neovim.nix
    ./ssh.nix
    ./tmux.nix
  ];

  home = {
    username = "zezocas";
    homeDirectory = "/home/zezocas";
    stateVersion = "25.11";
    packages = with pkgs; [
      bash
      btop
      fzf
      openssl
      speedtest-cli
      tmux
      zip
    ];
  };

  home.activation.pruneOldGenerations = lib.hm.dag.entryAfter [ "nixos-rebuild" ] ''
    nix-env --delete-generations '+4'
  '';
}

{
  description = "My system configuration";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    { nixpkgs, home-manager, ... }@inputs:
    let
      system = "x86_64-linux";

      # The hostname is the attribute name below - it is the single source of
      # truth. It gets passed to the system config (networking.hostName) and is
      # used to pick the host directory. Do not repeat it inside the host files.
      mkHost =
        hostname:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs hostname; };
          modules = [
            ./modules/system.nix
            ./hosts/${hostname}/configuration.nix
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = { inherit inputs; };
              home-manager.users.zezocas = import ./modules/home.nix;
            }
          ];
        };
    in
    {
      nixosConfigurations = {
        E16 = mkHost "E16";
        pixa = mkHost "pixa";
        cacete = mkHost "cacete";
        X260 = mkHost "X260";
      };
    };
}

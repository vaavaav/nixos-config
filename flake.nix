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

      mkHost =
        hostname:
        {
          configDir ? hostname,
        }:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit inputs hostname;
          };
          modules = [
            ./hosts/${configDir}/configuration.nix
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = {
                inherit inputs;
              };
              home-manager.users.zezocas = import ./hosts/${hostname}/home.nix;
            }
          ];
        };
    in
    {
      nixosConfigurations = {
        "E16" = mkHost "E16" { };
        "pixa" = mkHost "pixa" { };
        "cacete" = mkHost "cacete" { };
      };
    };
}

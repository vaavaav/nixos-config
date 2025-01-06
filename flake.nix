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
        hostname: users:
        let
          importUser =
            user:
            let
              path = ./users/${user};
            in
            if builtins.pathExists path then
              import path
            else
              throw "Host '${hostname}' references unknown user '${user}'. Create users/${user}/default.nix to define them.";
        in
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
              home-manager.users = builtins.listToAttrs (
                map (user: {
                  name = user;
                  value = importUser user;
                }) users
              );
            }
          ];
        };
    in
    {
      nixosConfigurations = {
        E16 = mkHost "E16" [ "zezocas" ];
        pixa = mkHost "pixa" [ "zezocas" ];
        cacete = mkHost "cacete" [ "zezocas" ];
        X260 = mkHost "X260" [ "zezocas" ];
      };
    };
}

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

      mkSystem =
        desktop: hostname: users:
        let
          importUser =
            user:
            let
              path = ./users/${user}/${if desktop then "desktop.nix" else "cli.nix"};
            in
            if builtins.pathExists path then
              import path
            else
              throw "Host '${hostname}' references unknown user '${user}'. Create ${toString path} to define them.";
        in
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs hostname; };
          modules = nixpkgs.lib.optional desktop ./modules/system.nix ++ [
            ./hosts/${hostname}/configuration.nix
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = { inherit inputs; };
              home-manager.backupFileExtension = "backup";
              home-manager.users = builtins.listToAttrs (
                map (user: {
                  name = user;
                  value = importUser user;
                }) users
              );
            }
          ];
        };

      mkDesktop = mkSystem true;
      mkServer = mkSystem false;
    in
    {
      nixosConfigurations = {
        E16 = mkDesktop "E16" [ "zezocas" ];
        pixa = mkDesktop "pixa" [ "zezocas" ];
        cacete = mkDesktop "cacete" [ "zezocas" ];
        X260 = mkDesktop "X260" [ "zezocas" ];
        rata = mkServer "rata" [ "zezocas" ];
      };
    };
}

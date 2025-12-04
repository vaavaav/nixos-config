{
  description = "My system configuration";

  inputs = {

    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      users = [
        "vaavaav"
      ];
      hosts = [
        "desktop"
        "E16"
      ];
      homeStateVersion = "25.11";
      stateVersion = "25.11";
    in
    {
      nixosConfigurations = nixpkgs.lib.foldl' (
        configs: hostname:
        configs
        // {
          "${hostname}" = nixpkgs.lib.nixosSystem {
            system = system;
            specialArgs = {
              inherit inputs hostname stateVersion;
            };
            modules = [
              ./hosts/${hostname}/configuration.nix
            ];
          };
        }
      ) { } hosts;

      homeConfigurations = nixpkgs.lib.foldl' (
        configs: username:
        configs
        // {
          "${username}" = home-manager.lib.homeManagerConfiguration {
            pkgs = nixpkgs.legacyPackages.${system};
            extraSpecialArgs = {
              inherit inputs homeStateVersion;
            };

            modules = [
              ./users/${username}/home.nix
            ];
          };
        }
      ) { } users;

    };
}

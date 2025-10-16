{
  description = "My system configuration";

  inputs = {

    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      homeStateVersion = "25.05";
      user = "vaavaav";
      hosts = [
        {
          hostname = "desktop";
          stateVersion = "25.05";
        }
        {
          hostname = "E16";
          stateVersion = "25.05";
        }
      ];

      makeSystem =
        { hostname, stateVersion }:
        nixpkgs.lib.nixosSystem {
          system = system;
          specialArgs = {
            inherit
              inputs
              stateVersion
              hostname
              user
              ;
          };

          modules = [
            ./hosts/${hostname}/configuration.nix
          ];
        };

    in
    {
      nixosConfigurations = nixpkgs.lib.foldl' (
        configs: host:
        configs
        // {
          "${host.hostname}" = makeSystem {
            inherit (host) hostname stateVersion;
          };
        }
      ) { } hosts;

      homeConfigurations.${user} = home-manager.lib.homeManagerConfiguration rec {
        pkgs = nixpkgs.legacyPackages.${system};
        extraSpecialArgs = {
          inherit inputs homeStateVersion user;
          autenticacao-gov-pt = import ./flakes/autenticacao-gov-pt {
            inherit pkgs;
            lib = pkgs.lib;
          };
        };

        modules = [
          ./users/${user}/home.nix
        ];
      };
    };
}

{
  description = "NixOS server configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    podman-flake = {
      url = "github:CRBroughton/nix-flakes?dir=podman-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    fish-flake = {
      url = "github:CRBroughton/nix-flakes?dir=fish-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      fish-flake,
      podman-flake,
      ...
    }:
    {
      nixosConfigurations.nixos-server = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./configuration.nix
          ./hardware-configuration.nix

          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.craig = {
              imports = [
                fish-flake.homeManagerModules.default
                podman-flake.homeManagerModules.default
                ./home.nix
              ];
            };
          }
        ];
      };
    };
}

{
  description = "NixOS server configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    fish-flake = {
      url = "github:CRBroughton/nix-flakes?dir=fish-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, fish-flake, ... }: {
    nixosConfigurations.nixos-server = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration.nix
        ./hardware-configuration.nix
        
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.craig = import ./home.nix;
          home-manager.extraSpecialArgs = { inherit fish-flake; };
        }
      ];
    };
  };
}

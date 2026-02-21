{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, disko, ... }: {
    nixosConfigurations.pi = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      modules = [
        "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
        disko.nixosModules.disko
        ./disk-config.nix
        ./configuration.nix
      ];
    };

    # Build with: nix build .#images.pi
    images.pi = self.nixosConfigurations.pi.config.system.build.sdImage;
  };
}
{
  description = "My modular NixOS configuration using flakes";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
  };

  outputs = { self, nixpkgs, ... }: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
      config = { allowUnfree = true; };
    };
  in {
    nixosConfigurations = {
      my-pc = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ./hosts/my-pc.nix
          ./modules/users.nix
          ./modules/packages.nix
          ./modules/desktop.nix
          ./modules/audio.nix
          ./modules/docker.nix
          ./modules/nvidia.nix
          ./modules/networking.nix
          ./modules/bootloader.nix
        ];
      };
    };
  };
}


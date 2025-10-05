{ config, pkgs, ... }:

{
  imports = [
    ../hardware-configuration.nix
  ];

  networking.hostName = "nixos";
  time.timeZone = "Europe/Moscow";
  nixpkgs.config.allowUnfree = true;
  system.stateVersion = "25.05";
}


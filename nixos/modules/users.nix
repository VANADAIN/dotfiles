{ config, pkgs, ... }:

{
  users.users.ruarin = {
    isNormalUser = true;
    description = "ruarin";
    extraGroups = [ "networkmanager" "wheel" "audio" "pulse-access" ];
    shell = pkgs.fish;
    packages = with pkgs; [];
  };

  programs.fish.enable = true;
  programs.zoxide.enable = true;
  programs.zoxide.enableFishIntegration = true;
}


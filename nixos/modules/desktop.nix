{ config, pkgs, ... }:

{
  services.xserver = {
    enable = true;

    desktopManager.xterm.enable = false;

    windowManager.i3 = {
      enable = true;
      extraPackages = with pkgs; [
        dmenu i3status i3blocks
      ];
    };

    videoDrivers = [ "nvidia" ];
    xkb = {
      layout = "us,ru";
      variant = "";
      options = "grp:alt_shift_toggle";
    };
  };

  services.displayManager.defaultSession = "none+i3";
  services.gvfs.enable = true;
  services.printing.enable = true;
}


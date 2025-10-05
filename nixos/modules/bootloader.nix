{ config, pkgs, ... }:

{
  boot.loader = {
    systemd-boot.enable = false;
    efi.canTouchEfiVariables = true;
    efi.efiSysMountPoint = "/boot";

    grub = {
      enable = true;
      useOSProber = true;
      efiSupport = true;
      device = "nodev";
      fsIdentifier = "uuid";
      extraEntries = ''
        menuentry "Reboot" {
          reboot
        }
      '';
    };
  };

  boot.kernelPackages = pkgs.linuxPackages_6_16;
}


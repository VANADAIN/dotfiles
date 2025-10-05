{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # System
    pciutils usbutils wget gcc binutils pkg-config openssl nix-ld

    # Media
    vlc ffmpeg mpv

    # Audio
    pavucontrol helvum pasystray

    # Terminal
    xclip wl-clipboard fish kitty neovim htop tree git neofetch unzip bat zoxide

    # Docker
    docker docker-compose nvidia-container-toolkit libnvidia-container

    # Languages
    rustup go bun nodejs_22 python312 uv odin

    # Dev
    biome foundry

    # Tray
    flameshot

    # Fonts
    corefonts dejavu_fonts noto-fonts noto-fonts-cjk-sans noto-fonts-emoji
    liberation_ttf liberation_ttf_v1 fira-code fira-code-symbols
    mplus-outline-fonts.githubRelease dina-font proggyfonts
    helvetica-neue-lt-std fragment-mono source-code-pro

    # Desktop apps
    nautilus telegram-desktop slack brave xfce.thunar i3 i3blocks
    nekoray windsurf discord
  ];
}


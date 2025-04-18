/*
  This file contains all common options for desktop environments. It should
  ensure that all workstations are provided with basic configuration for common
  desktop-specific stuff like sound, fonts and services that only make sense
  to be available on workstations.

  Desktop-specific configuration options are in '<desktop>/default.nix' and
  should only contain options relative to this specific desktop.
*/

{
  config,
  desktop,
  isInstall,
  lib,
  pkgs,
  ...
}:

let
  # Precompute predicates
  hasNvidia = builtins.elem "nvidia" config.services.xserver.videoDrivers;
in
{
  imports = lib.optional (builtins.pathExists (./. + "/${desktop}")) ./${desktop};

  # Enable RealtimeKit to acquire realtime scheduling priority for I/O threads
  security.rtkit.enable = true;

  boot = {
    consoleLogLevel = 0;
    initrd.verbose = false;

    kernelParams =
      [
        # Disable blinking cursor in virtual terminal
        "vt.global_cursor_default=0"
        # Improve system performance, load balancing, and interrupt handling efficiency
        # on multi-core systems by allowing interrupt handling to be threaded and
        # distributed across multiple CPU cores
        "threadirqs"
      ]
      # Silent boot on installs
      # https://wiki.archlinux.org/title/silent_boot
      ++ lib.optionals isInstall [
        "quiet"
        "rd.systemd.show_status=auto"
        "udev.log_level=3"
        "rd.udev.log_level=3"
      ];

    # Boot splashscreen
    # https://wiki.archlinux.org/title/plymouth
    plymouth = {
      enable = true;
      theme = "catppuccin-mocha";
      themePackages = [ (pkgs.catppuccin-plymouth.override { variant = "mocha"; }) ];
    };
  };

  # Add WPA GUI if wireless networks are enabled
  environment.systemPackages =
    with pkgs;
    [
      ghostty
      brave
    ]
    ++ lib.optional config.networking.wireless.enable wpa_supplicant_gui;

  fonts = {
    # Basic set of fonts
    enableDefaultPackages = true;

    fontconfig = {
      enable = true;
      antialias = true;

      defaultFonts = {
        emoji = [ "Noto Color Emoji" ];
        monospace = [ "Hurmit Nerd Font Mono" ];
        sansSerif = [ "Noto Sans" ];
        serif = [ "Noto Serif" ];
      };

      # Improve rendering sharpness
      hinting = {
        enable = true;
        autohint = true;

        # Amount of font reshaping
        # slight will make the font more fuzzy to line up to the grid but will be better in retaining font shape
        style = "slight";
      };

      subpixel = {
        lcdfilter = "light";
        rgba = "rgb";
      };
    };

    # Install additional fonts
    packages = with pkgs; [
      # Only grab some fonts from nerdfonts
      # https://wiki.nixos.org/wiki/Fonts#Installing_specific_nerdfonts
      (nerdfonts.override {
        # Available fonts: https://github.com/NixOS/nixpkgs/blob/nixos-23.11/pkgs/data/fonts/nerdfonts/shas.nix
        fonts = [
          "Hermit"
        ];
      })
      (noto-fonts.override {
        variants = [
          "NotoSerif"
          "NotoSans"
        ];
      })
      # Emoji
      noto-fonts-color-emoji
    ];
  };

  hardware = {
    # Enable hardware accelerated graphics drivers (ie. OpenGL)
    graphics.enable = true;

    # Bluetooth configuration
    # https://wiki.nixos.org/wiki/Bluetooth
    # https://wiki.archlinux.org/title/bluetooth
    bluetooth = lib.mkIf isInstall {
      enable = true;
      package = pkgs.bluez;
      powerOnBoot = true;

      settings = {
        General = {
          # A2DP
          Enable = "Source,Sink,Media,Socket";

          # Experimental features (eg. devices battery percentage)
          Experimental = true;
        };
      };
    };

    # NVIDIA configuration if host has NVIDIA drivers
    # https://wiki.nixos.org/wiki/NVIDIA
    nvidia = lib.mkIf (hasNvidia && isInstall) {
      # Fix screen tearing with prime
      modesetting.enable = true;

      # Enable nvidia-settings menu
      nvidiaSettings = true;

      # Use proprietary kernel module
      open = false;

      # Use latest production grade drivers
      package = config.boot.kernelPackages.nvidiaPackages.production;

      # Disable dynamic power management
      powerManagement = {
        enable = false;
        finegrained = false;
      };

      # Enable prime sync mode
      prime = {
        offload.enable = false;
        sync.enable = true;
      };
    };
  };

  services = {
    # Enable CUPS on installs
    printing.enable = isInstall;

    # Sound
    pipewire = {
      # Enable ALSA support
      alsa.enable = true;
      alsa.support32Bit = true;

      # Enable PulseAudio server emulation
      pulse.enable = true;
    };

    # Disable xterm
    xserver = {
      desktopManager.xterm.enable = false;
      excludePackages = [ pkgs.xterm ];
    };
  };

  system.userActivationScripts.fullBrightness.text = ''
    #!${pkgs.bash}/bin/bash

    ${pkgs.brightnessctl}/bin/brightnessctl s +100%
  '';
}

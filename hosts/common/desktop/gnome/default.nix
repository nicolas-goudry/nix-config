{ config, hostname, lib, pkgs, username, ... }:

let
  # Define power-users
  powerUsers = [ "nicolas" ];

  # Precompute predicates
  isInstall = builtins.substring 0 4 hostname != "iso-";
  isPowerUser = builtins.elem username powerUsers;

  # Classic packages configuration
  classic = {
    exclude = with pkgs; [
      epiphany # Web browser
      gnome-connections # Remote desktop client
      gnome-console # Replaced by alacritty
      gnome-photos # Replaced by loupe
      gnome-tour # Tour app
      gnome-user-docs # Help app
      orca # Screen reader
      gnome.gnome-characters # Utility to find unusual characters
      gnome.gnome-logs # Systemd journal log viewer
      gnome.gnome-music # Music player
      gnome.totem # Video player
    ]
    # Exclude some apps from ISO images
    ++ lib.optionals (!isInstall) [
      loupe # Image viewer
      snapshot # Camera app
      gnome.gnome-calculator # Calculator
      gnome.simple-scan # Scanner utility
    ];

    add = lib.optionals isInstall (with pkgs; [
      loupe # Image viewer
    ]);
  };

  # Power-users packages configuration
  power = {
    exclude = with pkgs; [
      baobab # Disk usage analysis
      gnome-text-editor # Default text editor
      snapshot # Camera app
      gnome.gnome-backgrounds # Default wallpaper set
      gnome.gnome-calendar # Calendar app
      gnome.gnome-clocks # Clock app
      gnome.gnome-contacts # Contacts app
      gnome.gnome-font-viewer # Font viewer
      gnome.gnome-maps # Maps app
      gnome.gnome-themes-extra # Extra themes
      gnome.gnome-weather # Weather app
      gnome.yelp # Help viewer
    ];

    add = with pkgs; lib.optionals isInstall [
      gnome.gnome-control-center # Utility to configure Gnome
      gnome.gnome-tweaks # Gnome tweaks
    ];
  };
in
{
  environment = {
    gnome.excludePackages = classic.exclude ++ lib.optionals (!isInstall || isPowerUser) power.exclude;
    systemPackages = classic.add ++ lib.optionals isPowerUser power.add
      # Add calamares installer without autostart on ISO images for graphical installation
      # https://github.com/NixOS/nixpkgs/blob/23.11/nixos/modules/installer/cd-dvd/installation-cd-graphical-calamares.nix
      ++ lib.optionals (!isInstall) (with pkgs; [
      calamares-nixos
      calamares-nixos-extensions
      glibcLocales
      libsForQt5.kpmcore
    ] ++ lib.optional config.networking.wireless.enable wpa_supplicant_gui);

    # Fix "Your GStreamer installation is missing a plug-in"
    # https://discourse.nixos.org/t/what-gstreamer-plugin-am-i-missing-thats-preventing-me-from-seeing-audio-video-properties/32824
    # https://github.com/NixOS/nixpkgs/issues/53631
    # https://github.com/NixOS/nixpkgs/issues/195936
    sessionVariables.GST_PLUGIN_SYSTEM_PATH_1_0 = lib.makeSearchPathOutput "lib" "lib/gstreamer-1.0" (with pkgs.gst_all_1; [
      gst-plugins-good
      gst-plugins-bad
      gst-plugins-ugly
      gst-libav
    ]);
  };

  # Support choosing from any locale on ISO images
  # https://github.com/NixOS/nixpkgs/blob/23.11/nixos/modules/installer/cd-dvd/installation-cd-graphical-calamares.nix
  i18n.supportedLocales = lib.mkIf (!isInstall) [ "all" ];

  programs = {
    # Phone dialer and call handler
    calls.enable = false;

    # Document viewer
    evince.enable = isInstall && !isPowerUser;

    # Archive manager
    file-roller.enable = isInstall && !isPowerUser;

    # Email client
    geary.enable = false;

    # Disks daemon (udisks2 GUI)
    gnome-disks.enable = isInstall;

    # Default terminal
    gnome-terminal.enable = isInstall && !isPowerUser;

    # Password/key manager
    seahorse.enable = isInstall;

    dconf.profiles.user.databases = [{
      settings = lib.mkIf (!isInstall) (with lib.gvariant; {
        # Set “favorite” apps shown in overview dock
        "org/gnome/shell".favorite-apps = [ "io.calamares.calamares.desktop" "gparted.desktop" "Alacritty.desktop" "nixos-manual.desktop" ];

        # Ensure ISO images do not go to sleep
        "org/gnome/desktop/session".idle-delay = mkUint32 0;
        "org/gnome/settings-daemon/plugins/power" = {
          idle-dim = false;
          sleep-inactive-ac-type = "nothing";
          sleep-inactive-battery-timeout = "1800";
        };
      });
    }];
  };

  qt = {
    # Enable Qt configuration, including theming
    # Required for Qt plugins to work in installed profiles
    enable = true;

    # Select platform theme for Qt applications
    platformTheme = "gnome";

    # Select style for Qt applications
    style = "adwaita-dark";
  };

  # Automatically unlock Gnome keyring upon login
  security.pam.services.gdm.enableGnomeKeyring = true;

  services = {
    udev.packages = with pkgs; [ gnome.gnome-settings-daemon ];

    # Disable autologin
    displayManager.autoLogin.enable = false;

    gnome = {
      # Collection of services for storing addressbooks and calendars
      evolution-data-server.enable = lib.mkForce (!isPowerUser);

      # Disable Gnome games
      games.enable = false;

      # Native host connector for Gnome Shell browser extension
      gnome-browser-connector.enable = isInstall;

      # Single sign-on framework for Gnome online accounts
      gnome-online-accounts.enable = isInstall && !isPowerUser;

      # Quick previewer for nautilus
      sushi.enable = true;

      # Files indexation and search tool
      tracker.enable = isInstall;
      tracker-miners.enable = isInstall;
    };

    xserver = {
      enable = true;

      # Enable Gnome display manager
      displayManager.gdm.enable = true;

      # Enable Gnome desktop manager
      desktopManager.gnome.enable = true;
    };
  };
}

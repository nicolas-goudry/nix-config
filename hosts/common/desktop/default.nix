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
  isGnome = desktop == "gnome";
in
{
  imports = lib.optional (builtins.pathExists (./. + "/${desktop}")) ./${desktop};

  # Enable RealtimeKit to acquire realtime scheduling priority for I/O threads
  security.rtkit.enable = true;

  boot = {
    consoleLogLevel = 0;
    initrd.verbose = false;

    kernelParams = [
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

  # Default system programs
  environment.systemPackages =
    with pkgs;
    [
      ghostty
    ]
    # Add WPA GUI if wireless networks are enabled
    ++ lib.optional config.networking.wireless.enable wpa_supplicant_gui;

  fonts = {
    # Basic set of fonts
    enableDefaultPackages = true;

    fontconfig = {
      enable = true;
      antialias = true;

      # Select default fonts
      # NOTE: fonts must be installed (see fonts.packages)
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
        # "slight" will make the font more fuzzy to line up to the grid but will be better in retaining font shape
        style = "slight";
      };

      subpixel = {
        lcdfilter = "light";
        rgba = "rgb";
      };
    };

    # Install additional fonts
    packages = with pkgs; [
      nerd-fonts.hurmit
      (noto-fonts.override {
        variants = [
          "NotoSerif"
          "NotoSans"
        ];
      })
      # Emojis font
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

  # Configure common policies for Chromium-based browsers (ie. Chromium, Google Chrome and Brave)
  # Can be disabled (or further tweaked) per-host, maybe using lib.mkForce
  programs.chromium = {
    # WARN: this does not install Chromium!!!
    enable = lib.mkDefault true;
    # Default home is the Bonjourr extension page
    homepageLocation = lib.mkDefault "chrome-extension://dlnejlppicbjfcfcedcflplfjajinajd/index.html";
    # Default search provider
    defaultSearchProviderEnabled = true;
    defaultSearchProviderSearchURL = "https://duckduckgo.com/?q={searchTerms}";
    defaultSearchProviderSuggestURL = "https://duckduckgo.com/ac/?q={searchTerms}&type=list";

    # Reference: https://www.chromium.org/administrators/configuring-other-preferences/
    initialPrefs = lib.mkDefault {
      browser.show_home_button = false;
      bookmark_bar.show_on_all_tabs = true;
      sync_promo.show_on_first_run_allowed = false;
      # Automatically restore previous session on startup
      session.restore_on_startup = 1;

      # Set first run tab to new tab page (extensions are not installed yet)
      first_run_tabs = [
        "chrome://new-tab-page"
      ];
    };

    # Reference: https://chromeenterprise.google/intl/en_us/policies/
    extraOpts = {
      # Disable credit card suggestions
      AutofillCreditCardEnabled = false;
      # Remove Chrome Labs icon from toolbar
      BrowserLabsEnabled = false;
      # Always ask for geolocation
      DefaultGeolocationSetting = 3;
      # Always ask for notifications
      DefaultNotificationsSetting = 3;
      # Disable popups on all sites
      DefaultPopupsSetting = 2;
      # Enable memory saver and configure it for moderate memory savings
      HighEfficiencyModeEnabled = true;
      MemorySaverModeSavings = 0;
      # Disable subtitles translation (data is sent to Google)
      LiveTranslationEnabled = false;
      # Disable built-in password manager (we use Bitwarden)
      PasswordManagerEnabled = false;
      PasswordManagerPasskeysEnabled = false;
      # Always select system default printer in print preview
      PrintPreviewUseSystemDefaultPrinter = true;
      # Disable Chrome promotion pages
      PromotionsEnabled = false;
      # Spell check languages (must be installed)
      "SpellcheckLanguage" = [
        "en-US"
        "fr"
      ];

      # Extensions configuration
      # Reference: https://www.chromium.org/administrators/policy-list-3/extension-settings-full/
      ExtensionSettings = {
        # Force extensions installation from Nix configuration
        "*" = {
          installation_mode = "blocked";
          blocked_install_message = "Extensions must be configured in NixOS/Home Manager configuration";
        };

        # Bitwarden Password Manager
        nngceckbapebfimnlniiiahkandclblb = {
          toolbar_pin = "default_pinned";
        };

        # Ghostery
        mlomiejdfkolichcflejclcbmpeaniij = {
          toolbar_pin = "default_pinned";
        };
      };
    };

    # Basic set of extensions
    extensions = [
      # Bitwarden Password Manager
      "nngceckbapebfimnlniiiahkandclblb"
      # Bonjourr Minimalist Startpage
      "dlnejlppicbjfcfcedcflplfjajinajd"
      # Ghostery
      "mlomiejdfkolichcflejclcbmpeaniij"
      # GNOME Shell Integration
      (lib.mkIf isGnome "gphhapmejobijbbhgpjhcjognlahblep")
      # Accept all cookies
      "ofpnikijgfhlmmjlpkfaifhhdonchhoi"
      # JSON Viewer Pro
      "eifflpmocdbdmepbjaopkkhbfmdgijcc"
    ];
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

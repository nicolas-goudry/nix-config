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
      gnome.gnome-music # Replaced by Amberol
      gnome.totem # Replaced by VLC
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
      gnomeExtensions.alttab-scroll-workaround # Fix bug when scrolling in an app is repeated in another when switching between them
      gnomeExtensions.appindicator # Allow apps to add themself to the icon tray
      gnomeExtensions.bluetooth-quick-connect # Add a bluetooth connection menu
      gnomeExtensions.dash-to-dock # Dash dock (like OSX)
      gnomeExtensions.emoji-copy # Emoji picker
      gnomeExtensions.grand-theft-focus # Remove 'Window is ready' notification
      gnomeExtensions.gsconnect # Connect to and control Android phones
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
      gnomeExtensions.clipboard-indicator # Clipboard manager with history
      gnomeExtensions.notification-timeout # Configure notifications timeout
      gnomeExtensions.resource-monitor # Show resources usage in tray
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
      settings = with lib.gvariant; (lib.mkMerge [
        {
          "org/gnome/desktop/a11y".always-show-universal-access-status = false;
          "org/gnome/desktop/calendar".show-weekdate = true;
          "org/gnome/desktop/datetime".automatic-timezone = true;
          "org/gnome/desktop/media-handling".autorun-never = true;
          "org/gnome/desktop/remote-desktop/rdp".enable = false;
          "org/gnome/desktop/session".idle-delay = mkUint32 300;
          "org/gnome/settings-daemon/plugins/media-keys".home = [ "<Super>e" ];
          "org/gnome/settings-daemon/plugins/sharing/gnome-user-share-webdav".enabled-connections = mkEmptyArray type.string;
          "org/gnome/settings-daemon/plugins/sharing/rygel".enabled-connections = mkEmptyArray type.string;
          "org/gnome/shell/app-switcher".current-workspace-only = false;
          "org/gnome/system/location".enabled = true;

          "org/gnome/desktop/input-sources" = {
            per-window = false;
            show-all-sources = true;
            sources = [
              (mkTuple [ "xkb" "fr+bepo" ])
              (mkTuple [ "xkb" "fr+oss" ])
            ];
            # WARN: keep in sync with services.xserver.xkb.options
            xkb-options = [
              "lv3:ralt_switch"
              "grp:win_space_toggle"
              "terminate:ctrl_alt_bksp"
            ];
          };

          "org/gnome/desktop/interface" = {
            clock-format = "24h";
            color-scheme = "prefer-dark";
            clock-show-date = true;
            clock-show-seconds = true;
            enable-hot-corners = false;
            gtk-enable-primary-paste = true;
            show-battery-percentage = true;
          };

          "org/gnome/desktop/notifications" = {
            show-banners = true;
            show-in-lock-screen = true;
          };

          "org/gnome/desktop/peripherals/mouse" = {
            accel-profile = "default";
            left-handed = false;
            natural-scroll = false;
            speed = 0.0;
          };

          "org/gnome/desktop/peripherals/touchpad" = {
            click-method = "fingers";
            disable-while-typing = true;
            edge-scrolling-enabled = false;
            natural-scroll = true;
            send-events = "enabled";
            speed = 0.0;
            tap-to-click = true;
            two-finger-scrolling-enabled = true;
          };

          "org/gnome/desktop/privacy" = {
            disable-camera = false;
            disable-microphone = false;
            old-files-age = mkUint32 30;
            recent-files-max-age = "-1";
            remember-recent-files = true;
            remove-old-temp-files = true;
            remove-old-trash-files = true;
          };

          "org/gnome/desktop/screensaver" = {
            lock-delay = mkUint32 0;
            lock-enabled = true;
          };

          "org/gnome/desktop/search-providers" = {
            disable-external = false;
            sort-order = [
              "org.gnome.Nautilus.desktop"
              "org.gnome.Documents.desktop"
              "org.gnome.Settings.desktop"
            ];
            disabled = [
              "org.gnome.Calculator.desktop"
              "org.gnome.seahorse.Application.desktop"
            ];
          };

          "org/gnome/desktop/sound" = {
            allow-volume-above-100-percent = false;
            event-sounds = true;
          };

          "org/gnome/desktop/wm/keybindings" = {
            switch-applications = mkEmptyArray type.string;
            switch-applications-backward = mkEmptyArray type.string;
            switch-windows = [ "<Alt>Tab" ];
            switch-windows-backward = [ "<Shift><Alt>Tab" ];
            show-desktop = [ "<Super>d" ];
          };

          "org/gnome/desktop/wm/preferences" = {
            action-double-click-titlebar = "toggle-maximize";
            action-right-click-titlebar = "menu";
            button-layout = "appmenu:minimize,maximize,close";
            focus-mode = "click";
            focus-new-windows = "smart";
            mouse-button-modifier = "<Super>";
          };

          "org/gnome/mutter" = {
            attach-modal-dialogs = true;
            center-new-windows = true;
            dynamic-workspaces = true;
            edge-tilings = true;
            workspaces-only-on-primary = false;
          };

          "org/gnome/nautilus/icon-view".captions = [
            "none"
            "none"
            "none"
          ];

          "org/gnome/nautilus/list-view" = {
            default-zoom-level = "small";
            use-tree-view = true;
          };

          "org/gnome/nautilus/preferences" = {
            click-policy = "double";
            default-folder-viewer = "list-view";
            recursive-search = "local-only";
            search-filter-time-type = "last_modified";
            show-delete-permanently = true;
            show-directory-item-counts = "local-only";
            show-image-thumbnails = "local-only";
          };

          "org/gnome/settings-daemon/plugins/color" = {
            night-light-enabled = true;
            night-light-schedule-automatic = false;
            night-light-schedule-from = 20.0;
            night-light-schedule-to = 7.0;
          };

          "org/gnome/settings-daemon/plugins/power" = {
            idle-dim = true;
            power-button-action = "suspend";
            power-saver-profile-on-low-battery = true;
            sleep-inactive-ac-type = "nothing";
            sleep-inactive-battery-timeout = "900";
            sleep-inactive-battery-type = "suspend";
          };

          "org/gtk/gtk4/settings/file-chooser" = {
            show-hidden = true;
            sort-directories-first = true;
            view-type = "list";
          };

          "org/gtk/settings/file-chooser" = {
            clock-format = "24h";
            show-hidden = true;
            sort-directories-first = true;
          };
        }
        # Only install and configure extensions on installs
        (lib.mkIf isInstall {
          # Enabled extensions
          "org/gnome/shell".enabled-extensions = [
            "alt-tab-scroll-workaround@lucasresck.github.io"
            "appindicatorsupport@rgcjonas.gmail.com"
            "bluetooth-quick-connect@bjarosze.gmail.com"
            "dash-to-dock@micxgx.gmail.com"
            "drive-menu@gnome-shell-extensions.gcampax.github.com"
            "emoji-copy@felipeftn"
            "grand-theft-focus@zalckos.github.com"
            "gsconnect@andyholmes.github.io"
          ] ++ lib.optionals isPowerUser [
            "clipboard-indicator@tudmotu.com"
            "notification-timeout@chlumskyvaclav.gmail.com"
            "Resource_Monitor@Ory0n"
          ];

          # Extensions configuration
          "org/gnome/shell/extensions/bluetooth-quick-connect" = {
            bluetooth-auto-power-off = false;
            bluetooth-auto-power-on = true;
            debug-mode-on = false;
            keep-menu-on-toggle = true;
            refresh-button-on = false;
            show-battery-icon-on = true;
            show-battery-value-on = true;
          };

          "org/gnome/shell/extensions/dash-to-dock" = {
            multi-monitor = true;
            dock-position = "BOTTOM";
            dock-fixed = true;
            extend-height = true;
            height-fraction = "0.9";
            always-center-icons = false;
            autohide = false;
            autohide-in-fullscreen = false;
            dash-max-icon-size = "32";
            icon-size-fixed = false;
            preview-size-scale = "0.0";
            show-favorites = true;
            show-running = true;
            show-windows-preview = true;
            isolate-workspaces = false;
            isolate-monitors = false;
            workspace-agnostic-urgent-windows = true;
            scroll-to-focused-application = true;
            show-dock-urgent-notify = true;
            show-show-apps-button = true;
            show-apps-at-top = false;
            animate-show-apps = true;
            show-apps-always-in-the-edge = true;
            show-trash = true;
            show-mounts = true;
            show-mounts-only-mounted = true;
            show-mounts-network = false;
            isolate-locations = true;
            dance-urgent-applications = true;
            hide-tooltip = true;
            show-icons-emblems = true;
            show-icons-notifications-counter = true;
            application-counter-overrides-notifications = true;
            hot-keys = false;
            click-action = "focus-minimize-or-previews";
            shift-click-action = "minimize";
            middle-click-action = "launch";
            shift-middle-click-action = "launch";
            scroll-action = "cycle-windows";
            custom-theme-shrink = true;
            disable-overview-on-startup = true;
            apply-custom-theme = false;
            running-indicator-style = "DEFAULT";
            custom-background-color = true;
            background-color = "rgb(0,0,0)";
            transparency-mode = "FIXED";
            background-opacity = "0.7";
          };
        })
        # Only install and configure power-users extensions on installs
        (lib.mkIf (isInstall && isPowerUser) {
          "org/gnome/shell/extensions/clipboard-indicator" = {
            cache-only-favorites = false;
            cache-size = "1024";
            confirm-clear = true;
            disable-down-arrow = true;
            display-mode = "0";
            enable-keybindings = false;
            history-size = "50";
            move-item-first = true;
            notify-on-copy = false;
            preview-size = "30";
            refresh-interval = "1000";
            strip-text = false;
            topbar-preview-size = "10";
          };

          "org/gnome/shell/extensions/notification-timeout" = {
            always-normal = true;
            ignore-idle = true;
            timeout = "5000";
          };

          "com/github/Ory0n/Resource_Monitor" = {
            # Global
            refreshtime = "2";
            extensionposition = "right";
            leftclickstatus = "gnome-system-monitor";
            rightclickstatus = true;
            decimalsstatus = true;
            iconsstatus = true;
            iconsposition = "left";
            itemsposition = [
              "cpu"
              "ram"
              "swap"
              "stats"
              "space"
              "eth"
              "wlan"
              "gpu"
            ];

            # CPU
            cpustatus = true;
            cpuwidth = "0";
            cpufrequencystatus = false;
            cpufrequencywidth = "0";
            cpufrequencyunitmeasure = "auto";
            cpuloadaveragestatus = false;
            cpuloadaveragewidth = "0";

            # RAM
            ramstatus = true;
            ramwidth = "0";
            ramunit = "numeric";
            ramunitmeasure = "auto";
            rammonitor = "used";

            # Swap
            swapstatus = false;
            swapwidth = "0";
            swapunit = "numeric";
            swapunitmeasure = "auto";
            swapmonitor = "used";

            # Disk
            diskdevicesdisplayall = false;
            diskstatsstatus = false;
            diskstatswidth = "0";
            diskstatsmode = "multiple";
            diskstatsunitmeasure = "auto";
            diskspacestatus = false;
            diskspacewidth = "0";
            diskspaceunit = "numeric";
            diskspaceunitmeasure = "auto";
            diskspacemonitor = "used";

            # Net
            netautohidestatus = false;
            netunit = "bytes";
            netunitmeasure = "auto";
            netethstatus = false;
            netethwidth = "0";
            netwlanstatus = false;
            netwlanwidth = "0";

            # Thermal
            thermaltemperatureunit = "c";
            thermalcputemperaturestatus = false;
            thermalgputemperaturestatus = false;

            # GPU
            gpustatus = false;
            gpuwidth = "0";
            gpumemoryunit = "numeric";
            gpumemoryunitmeasure = "auto";
            gpumemorymonitor = "used";
            gpudisplaydevicename = false;
          };
        })
      ]);
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
      tracker.enable = !isInstall;
      tracker-miners.enable = !isInstall;
    };

    xserver = {
      enable = true;

      displayManager = {
        # Disable autologin
        autoLogin.enable = false;

        # Enable GNOME Display Manager
        gdm.enable = true;
      };

      # Enable GNOME desktop manager
      desktopManager.gnome.enable = true;
    };
  };
}

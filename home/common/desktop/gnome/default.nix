{
  config,
  lib,
  pkgs,
  ...
}:

let
  gnomeThemePkg = pkgs.catppuccin-gtk.override {
    accents = [ "red" ];
    size = "compact";
    tweaks = [ "rimless" ];
    variant = "mocha";
  };
  gnomeThemeName = "Catppuccin-Mocha-Compact-Red-Dark";
  cursorsThemePkg = pkgs.catppuccin-cursors.mochaRed;
  cursorsThemeName = "Catppuccin-Mocha-Red-Cursors";
in
{
  # Default gnome configuration via dconf
  dconf.settings =
    with lib.gvariant;
    (lib.mkMerge [
      {
        "org/gnome/desktop/a11y".always-show-universal-access-status = false;
        "org/gnome/desktop/calendar".show-weekdate = true;
        "org/gnome/desktop/datetime".automatic-timezone = true;
        "org/gnome/desktop/media-handling".autorun-never = true;
        "org/gnome/desktop/remote-desktop/rdp".enable = false;
        "org/gnome/desktop/session".idle-delay = mkUint32 300;
        "org/gnome/settings-daemon/plugins/media-keys".home = [ "<Super>e" ];
        "org/gnome/settings-daemon/plugins/sharing/gnome-user-share-webdav".enabled-connections =
          mkEmptyArray type.string;
        "org/gnome/settings-daemon/plugins/sharing/rygel".enabled-connections = mkEmptyArray type.string;
        "org/gnome/shell/app-switcher".current-workspace-only = false;
        "org/gnome/shell/extensions/user-theme".name = gnomeThemeName;
        "org/gnome/system/location".enabled = true;

        "org/gnome/desktop/input-sources" = {
          per-window = false;
          show-all-sources = true;
          # TODO: move to user config
          sources = [
            (mkTuple [
              "xkb"
              "fr+bepo"
            ])
            (mkTuple [
              "xkb"
              "fr+oss"
            ])
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
          show-desktop = [ "<Super>d" ];
          switch-applications = mkEmptyArray type.string;
          switch-applications-backward = mkEmptyArray type.string;
          switch-input-source = [ "<Super>space" ];
          switch-input-source-backward = [ "<Shift><Super>space" ];
          switch-windows = [ "<Alt>Tab" ];
          switch-windows-backward = [ "<Shift><Alt>Tab" ];
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

        "org/gnome/settings-daemon/plugins/media-keys".custom-keybindings = [
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/"
        ];

        "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
          binding = "<Control><Alt>t";
          command = "alacritty";
          name = "Terminal";
        };

        "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1" = {
          binding = "<Super>k";
          command = "${pkgs.gnome.seahorse}/bin/seahorse";
          name = "Seahorse";
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

        # Enabled extensions
        "org/gnome/shell".enabled-extensions = [
          "alt-tab-scroll-workaround@lucasresck.github.io"
          "appindicatorsupport@rgcjonas.gmail.com"
          "bluetooth-quick-connect@bjarosze.gmail.com"
          "dash-to-dock@micxgx.gmail.com"
          "drive-menu@gnome-shell-extensions.gcampax.github.com"
          "emoji-copy@felipeftn"
          "grand-theft-focus@zalckos.github.com"
          "user-theme@gnome-shell-extensions.gcampax.github.com"
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

        "org/gnome/shell/extensions/notification-timeout" = {
          always-normal = true;
          ignore-idle = true;
          timeout = "5000";
        };
      }
    ]);

  # Customize GTK apps look
  gtk = {
    enable = true;

    # Enable catppuccin cursor theme (https://github.com/catppuccin/cursors)
    cursorTheme = {
      name = cursorsThemeName;
      package = cursorsThemePkg;
      size = 32;
    };

    # Define font to use
    font = {
      name = "Noto Sans";

      package = pkgs.noto-fonts.override {
        variants = [
          "NotoSans"
        ];
      };
    };

    # Make sure GTK2 apps use dark theme when available and display window control buttons
    gtk2.extraConfig = ''
      gtk-application-prefer-dark-theme = 1
      gtk-decoration-layout = "appmenu:minimize,maximize,close"
    '';

    # Make sure GTK3 apps use dark theme when available and display window control buttons
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
      gtk-decoration-layout = "appmenu:minimize,maximize,close";
    };

    # Make sure GTK4 apps use dark theme when available and display window control buttons
    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
      gtk-decoration-layout = "appmenu:minimize,maximize,close";
    };

    # Enable catppuccin icon theme (https://github.com/catppuccin/cursors)
    iconTheme = {
      name = cursorsThemeName;
      package = cursorsThemePkg;
    };

    # Add catppuccin theme (https://github.com/catppuccin/gtk)
    theme = {
      name = gnomeThemeName;
      package = gnomeThemePkg;
    };
  };

  home = {
    # Install gnome extensions
    packages = with pkgs.gnomeExtensions; [
      alttab-scroll-workaround # Fix bug when scrolling in an app is repeated in another when switching between them
      appindicator # Allow apps to add themself to the icon tray
      bluetooth-quick-connect # Add a bluetooth connection menu
      dash-to-dock # Dash dock (like OSX)
      emoji-copy # Emoji picker
      grand-theft-focus # Remove 'Window is ready' notification
    ];

    # Enable catppuccin cursor theme (https://github.com/catppuccin/cursors)
    pointerCursor = {
      name = cursorsThemeName;
      package = cursorsThemePkg;
      size = 32;
      gtk.enable = true;
      x11.enable = true;
    };
  };

  # Make sure GTK4 apps take theme in account
  xdg.configFile = {
    "gtk-4.0/assets".source =
      "${config.gtk.theme.package}/share/themes/${config.gtk.theme.name}/gtk-4.0/assets";
    "gtk-4.0/gtk.css".source =
      "${config.gtk.theme.package}/share/themes/${config.gtk.theme.name}/gtk-4.0/gtk.css";
    "gtk-4.0/gtk-dark.css".source =
      "${config.gtk.theme.package}/share/themes/${config.gtk.theme.name}/gtk-4.0/gtk-dark.css";
  };
}

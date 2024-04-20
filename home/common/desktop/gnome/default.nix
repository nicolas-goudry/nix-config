{ config, pkgs, ... }:

{
  # Customize GTK apps look
  gtk = {
    enable = true;

    # Add catppuccin cursor theme
    cursorTheme = {
      name = "catppuccin-mocha-red";
      package = pkgs.catppuccin-cursors.mochaRed;
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

    # Add catppuccin theme (https://github.com/catppuccin/gtk)
    theme = {
      name = "catppuccin-mocha-red-compact-rimless";

      package = pkgs.catppuccin-gtk.override {
        accents = [ "red" ];
        size = "compact";
        tweaks = [ "rimless" ];
        variant = "mocha";
      };
    };
  };

  home.pointerCursor = {
    name = "catppuccin-mocha-red";
    package = pkgs.catppuccin-cursors.mochaRed;
    size = 32;
    gtk.enable = true;
    x11.enable = true;
  };

  # Make sure GTK4 apps take theme in account
  xdg.configFile = {
    "gtk-4.0/assets".source = "${config.gtk.theme.package}/share/themes/${config.gtk.theme.name}/gtk-4.0/assets";
    "gtk-4.0/gtk.css".source = "${config.gtk.theme.package}/share/themes/${config.gtk.theme.name}/gtk-4.0/gtk.css";
    "gtk-4.0/gtk-dark.css".source = "${config.gtk.theme.package}/share/themes/${config.gtk.theme.name}/gtk-4.0/gtk-dark.css";
  };
}

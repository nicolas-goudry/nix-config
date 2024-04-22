{ desktop, lib, pkgs, ... }:

let
  isGnome = desktop == "gnome";
in
{
  imports = [
    (builtins.fetchTarball {
      url = "https://github.com/nicolas-goudry/earth-view/archive/v0.0.1.tar.gz";
      sha256 = "sha256:1xs8hmr8g4fqblih0pk1sqccp1nfcwmmbbqy4a0vvjwkvl8rmczr";
    })
  ];

  home.packages = lib.optional isGnome pkgs.gnome.pomodoro;

  dconf.settings = lib.mkIf isGnome {
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

    "org/gnome/shell".enabled-extensions = [
      "pomodoro@arun.codito.in"
    ];

    "org/gnome/pomodoro/preferences" = {
      enabled-plugins = [ "dark-theme" ];
      hide-system-notifications = false;
      long-break-duration = "900.0";
      long-break-interval = "4.0";
      pause-when-idle = true;
      pomodoro-duration = "1500.0";
      short-break-duration = "300.0";
      show-screen-notifications = true;
    };
  };

  services.earthView = lib.mkIf isGnome {
    enable = true;
    interval = "4h";
  };
}

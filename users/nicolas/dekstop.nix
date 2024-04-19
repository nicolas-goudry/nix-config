{ desktop, lib, pkgs, ... }:

{
  imports = [
    (pkgs.fetchFromGitHub {
      owner = "nicolas-goudry";
      repo = "earth-view";
      rev = "v0.0.1";
      hash = "sha256:1xs8hmr8g4fqblih0pk1sqccp1nfcwmmbbqy4a0vvjwkvl8rmczr";
    })
  ];

  dconf.settings = lib.mkIf desktop == "gnome" {
    "org/gnome/settings-daemon/plugins/media-keys".custom-keybindings = [
      "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
      "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/"
    ];

    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
      binding = "<Control><Alt>t";
      command = "${pkgs.alacritty}/bin/alacritty";
      name = "Terminal";
    };

    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1" = {
      binding = "<Super>k";
      command = "${pkgs.seahorse}/bin/seahorse";
      name = "Seahorse";
    };

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

  services.earthView = lib.mkIf desktop == "gnome" {
    enable = true;
    interval = "4h";
  };
}

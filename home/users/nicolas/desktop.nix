{ config, desktop, lib, pkgs, ... }:

let
  isGnome = desktop == "gnome";
in
{
  home.packages = with pkgs; [
    discord
    obsidian
    pika-backup
    slack
    spotify
  ] ++ lib.optionals isGnome [
    gnome.pomodoro # Pomodoro app
    gnomeExtensions.clipboard-indicator # Clipboard manager with history
    gnomeExtensions.gsconnect # Connect to and control Android phones
    gnomeExtensions.notification-timeout # Configure notifications timeout
    gnomeExtensions.resource-monitor # Show resources usage in tray
  ];

  dconf.settings = lib.mkIf isGnome {
    # Enabled extensions
    "org/gnome/shell" = {
      enabled-extensions = [
        "clipboard-indicator@tudmotu.com"
        "gsconnect@andyholmes.github.io"
        "notification-timeout@chlumskyvaclav.gmail.com"
        "pomodoro@arun.codito.in"
        "Resource_Monitor@Ory0n"
      ];

      favorite-apps = [
        "org.gnome.Nautilus.desktop"
        "google-chrome.desktop"
        "terminator.desktop"
        "code.desktop"
        "GitKraken.desktop"
        "dbeaver.desktop"
        "obsidian.desktop"
        "spotify.desktop"
      ];
    };

    # Extensions configuration
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
  };

  programs = {
    gitkraken = {
      enable = true;
      package = pkgs.unstable.gitkraken;
      acceptEULA = true;
      collapsePermanentTabs = true;
      enableCloudPatch = true;
      logLevel = "extended";
      skipTour = true;

      commitGraph = {
        showAuthor = true;
      };

      gpg = {
        signingKey = config.programs.git.signing.key;
        signCommits = config.programs.git.signing.signByDefault;
        signTags = config.programs.git.signing.signByDefault;
      };

      notifications = {
        enable = true;
        marketing = false;
      };

      tools.terminal = {
        default = "custom";
        package = pkgs.unstable.alacritty;
      };

      ui = {
        cli.autocomplete.tabBehavior = "navigation";
        extraThemes = [ "${pkgs.catppuccin-gitkraken}/catppuccin-mocha.jsonc" ];
        hideWorkspaceTab = true;
        theme = "catppuccin-mocha.jsonc";

        editor = {
          tabSize = 2;
          wrap = true;
        };
      };

      user = {
        email = config.programs.git.userEmail;
        name = config.programs.git.userName;
      };
    };
  };
}

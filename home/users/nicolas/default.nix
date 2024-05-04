{ config, hostname, lib, outputs, pkgs, ... }:

{
  imports = [
    outputs.homeManagerModules.gitkraken
  ];

  # Install user packages depending on host
  home.packages = with pkgs; [
    bruno
    kubectl
    kubernetes-helm
    k9s
  ] ++ lib.optionals (hostname == "g-xps") [
    dbeaver
    (google-cloud-sdk.withExtraComponents [ google-cloud-sdk.components.gke-gcloud-auth-plugin ])
    obsidian
  ] ++ lib.optionals (lib.elem hostname [ "g-aero" "g-xps" ]) [
    discord
    pika-backup
    qbittorrent
    slack
    spotify
    uget
  ];

  # User-specific git configuration
  programs = {
    git = {
      userName = "Nicolas Goudry";
      userEmail = "goudry.nicolas@gmail.com";

      signing = {
        key = "EC6884FA72B9465A";
        signByDefault = true;
      };
    };

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
        hideWorkspaceTab = true;
        theme = "dark";

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

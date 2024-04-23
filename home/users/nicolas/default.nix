{ hostname, pkgs, ... }:

{
  # Install user packages depending on host
  home.packages = with pkgs; [
    bruno
    gitkraken
    kubectl
    kubernetes-helm
    k9s
  ] ++ lib.optionals (hostname == "g-aero") [
    dbeaver
    discord
    (google-cloud-sdk.withExtraComponents [ google-cloud-sdk.components.gke-gcloud-auth-plugin ])
    obsidian
    pika-backup
    qbittorrent
    slack
    spotify
    uget
  ];

  # User-specific git configuration
  programs.git = {
    userName = "Nicolas Goudry";
    userEmail = "goudry.nicolas@gmail.com";

    signing = {
      key = "EC6884FA72B9465A";
      signByDefault = true;
    };
  };
}

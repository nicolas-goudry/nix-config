{ pkgs, ... }:

{
  home.packages = with pkgs; [
    bruno
    dbeaver
    discord
    gitkraken
    (google-cloud-sdk.withExtraComponents [ google-cloud-sdk.components.gke-gcloud-auth-plugin ])
    kubectl
    kubernetes-helm
    k9s
    obsidian
    pika-backup
    qbittorrent
    slack
    spotify
    teleport
    uget
  ];

  programs.git = {
    userName = "Nicolas Goudry";
    userEmail = "goudry.nicolas@gmail.com";

    signing = {
      key = "EC6884FA72B9465A";
      signByDefault = true;
    };
  };
}

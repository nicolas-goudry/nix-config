{ pkgs, ... }:

{
  home.packages = with pkgs; [
    uget
    # TODO: move to work config
    bruno
    dbeaver
    (google-cloud-sdk.withExtraComponents [
      google-cloud-sdk.components.gke-gcloud-auth-plugin
    ])
  ];
}

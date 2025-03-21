{ outputs, pkgs, ... }:

{
  imports = [
    outputs.homeManagerModules.gitkraken
  ];

  # Install user packages depending on host
  home.packages = with pkgs; [
    kubectl
    kubernetes-helm
    k9s
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

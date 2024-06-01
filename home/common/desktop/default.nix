{ desktop, inputs, lib, pkgs, username, ... }:

let
  inherit (pkgs.stdenv) isLinux;
in
{
  imports = [
    inputs.earth-view.homeManagerModules.earth-view
  ]
  # Desktop specific configuration for all users
  ++ lib.optional (builtins.pathExists (./. + "/${desktop}")) ./${desktop}
  # User specific desktop configuration
  ++ lib.optional (builtins.pathExists (./. + "/../../users/${username}/desktop.nix")) ../../users/${username}/desktop.nix;

  home.packages = with pkgs; [
    mpv-unwrapped # Video player
    warp # Secure file transfer
  ] ++ lib.optionals isLinux [
    amberol # Music player
    hunspell # Spell checker
    # Spell checker dictionaries
    hunspellDicts.en_US
    hunspellDicts.fr-any
    libreoffice-fresh # Productivity suite
  ];

  services.earth-view = {
    enable = isLinux;
    interval = "4h";
    gc.enable = true;
  };
}

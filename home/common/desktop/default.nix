{
  desktop,
  inputs,
  lib,
  pkgs,
  username,
  ...
}:

let
  inherit (pkgs.stdenv) isLinux;
in
{
  imports =
    [
      inputs.earth-view.homeManagerModules.earth-view
    ]
    # Desktop specific configuration for all users
    ++ lib.optional (builtins.pathExists (./. + "/${desktop}")) ./${desktop}
    # User specific desktop configuration
    ++ lib.optional (builtins.pathExists (
      ./. + "/../../${username}/desktop.nix"
    )) ../../${username}/desktop.nix;

  home.packages =
    with pkgs;
    [
      mpv-unwrapped # Video player
      warp # Secure file transfer
    ]
    ++ lib.optionals isLinux [
      amberol # Music player
      hunspell # Spell checker
      # Spell checker dictionaries
      hunspellDicts.en_US
      hunspellDicts.fr-any
      libreoffice-fresh # Productivity suite
    ];

  # Chromium Browser
  # NOTE: ideally, extensions are NOT declared here, but in programs.chromium.extensions in /hosts/common/desktop/default.nix
  #       This allows for a common Chromium-based browsers configuration
  programs.chromium = {
    enable = true;
    package = pkgs.unstable.chromium;

    commandLineArgs = [
      # Hide UI elements in fullscreen (X button and hint popup)
      "--hide-fullscreen-exit-ui"
      # Remove tabsearch button from tabstrip
      "--remove-tabsearch-button"
      # Disable top sites from new tab page
      "--disable-top-sites"
      # Force dark mode
      "--force-dark-mode"
      # Disable default browser check
      "--no-default-browser-check"
    ];

    # Spell check dictionaries to install
    # WARN: unless configured by policies, dictionaries are not used by default
    #       See programs.chromium.extraOpts in /hosts/common/desktop/default.nix for an example
    dictionaries = [
      pkgs.hunspellDictsChromium.fr_FR
      pkgs.hunspellDictsChromium.en_US
    ];
  };

  services.earth-view = {
    enable = isLinux;
    interval = "4h";
    gc.enable = true;
  };
}

{ lib, pkgs }:

with lib;

let
  datetimeSubmodule = import ./datetime.nix { inherit lib; };
  gitSubmodule = import ./git.nix { inherit lib pkgs; };
  gpgSubmodule = import ./gpg.nix { inherit lib pkgs; };
  graphSubmodule = import ./graph.nix { inherit lib; };
  notificationsSubmodule = import ./notifications.nix { inherit lib; };
  sshSubmodule = import ./ssh.nix { inherit lib; };
  toolsSubmodule = import ./tools.nix { inherit lib; };
  uiSubmodule = import ./ui.nix { inherit lib; };
  userSubmodule = import ./user.nix { inherit lib; };

  profileSubmodule = import ./profile.nix {
    inherit
      gitSubmodule
      gpgSubmodule
      graphSubmodule
      lib
      sshSubmodule
      toolsSubmodule
      uiSubmodule
      userSubmodule
      ;
  };
in
{
  enable = mkEnableOption "GitKraken";

  acceptEULA = mkOption {
    type = types.bool;
    default = false;
    description = ''
      Accept the End User License Agreement.
    '';
  };

  enableCloudPatch = mkOption {
    type = types.bool;
    default = false;
    description = ''
      Enable Cloud Patches. ToS will be automatically accepted
      when enabled.
    '';
  };

  collapsePermanentTabs = mkOption {
    type = types.bool;
    default = false;
    description = ''
      Force collapse permanent tabs (Focus and Worspace views).
    '';
  };

  commitGraph = mkOption {
    type = graphSubmodule "app";
    default = { };
    description = ''
      Commit graph settings.
    '';
  };

  datetime = mkOption {
    type = datetimeSubmodule;
    default = { };
    description = ''
      Date/time settings.
    '';
  };

  deleteOrigAfterMerge = mkOption {
    type = types.bool;
    default = false;
    description = ''
      GitKraken client will make `.orig` files during a merge. When
      disabled, these before and after files will not be
      automatically deleted.
    '';
  };

  git = mkOption {
    type = gitSubmodule "app";
    default = { };
    description = ''
      Git settings.
    '';
  };

  gpg = mkOption {
    type = gpgSubmodule;
    default = { };
    description = ''
      GPG settings.
    '';
  };

  logLevel = mkOption {
    type = types.enum [ "standard" "extended" "silly" ];
    default = "standard";
    description = ''
      Set log level in activity log.
    '';
  };

  notifications = mkOption {
    type = notificationsSubmodule;
    default = { };
    description = ''
      Notifications settings.
    '';
  };

  package = mkPackageOption pkgs "gitkraken" { } // {
    description = ''
      GitKraken package to install. Requires to allow unfree
      packages (`nixpkgs.config.allowUnfree = true`).
    '';
  };

  profiles = mkOption {
    type = types.listOf profileSubmodule;
    default = [{ isDefault = true; }];
    description = ''
      Profiles configuration. All settings in profile take
      precedence over global settings, ie. if a profile defines
      the `ssh` option and the global `ssh` option is defined, the
      profile option will be used for this profile.
    '';
  };

  rememberTabs = mkOption {
    type = types.bool;
    default = true;
    description = ''
      Remember open tabs when exiting.
    '';
  };

  skipTour = mkOption {
    type = types.bool;
    default = false;
    description = ''
      Skip the onboarding guide.
    '';
  };

  spellCheck = mkOption {
    type = types.bool;
    default = true;
    description = ''
      Enable spell checking.
    '';
  };

  ssh = mkOption {
    type = sshSubmodule;
    default = { };
    description = ''
      SSH settings.
    '';
  };

  tools = mkOption {
    type = toolsSubmodule;
    default = { };
    description = ''
      External tools settings.
    '';
  };

  ui = mkOption {
    type = uiSubmodule "app";
    default = { };
    description = ''
      UI settings.
    '';
  };

  user = mkOption {
    type = userSubmodule;
    default = { };
    description = ''
      User settings.
    '';
  };
}

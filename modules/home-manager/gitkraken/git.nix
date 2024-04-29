{ lib, pkgs }:

with lib;

mode:

assert (mode == "app" || mode == "profile");

types.submodule {
  options = attrsets.mergeAttrsList [
    {
      autoFetchInterval = mkOption {
        type = types.ints.between 0 60;
        default = 1;
        description = ''
          Set the number of minutes between auto-fetches. It will
          fetch all visible remotes for the repository. Setting the
          value to 0 will disable auto-fetch.
        '';
      };

      autoPrune = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Automatically remove any remote-tracking references that no
          longer exist on the remote.
        '';
      };

      autoUpdateSubmodules = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Automatically keep submodules up to date when performing Git
          actions.
        '';
      };

      defaultBranch = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          Set the default name when initializing a new repo. The app
          defaults to `main`.
        '';
      };
    }
    (if mode == "app" then {
      package = mkOption {
        type = types.package;
        default = pkgs.git;
        example = literalExpression "pkgs.gitAndTools.gitFull";
        description = ''
          Git package to install and use for Git actions. This option
          cannot be set if `git.enableBundledGit` is `true`. Note that
          not all Git actions are implemented through Git executable,
          so the bundled NodeGit will still be used for some actions,
          even if disabled.
        '';
      };

      syncConfig = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Automatically update the global Git configuration with the
          name and email address of the current profile.
        '';
      };

      useBundledGit = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Use bundled NodeGit for Git actions. When this option is set
          to `false`, the `git.package` option must be set. Note that
          not all Git actions are implemented through Git executable,
          so the bundled NodeGit will still be used for some actions,
          even if disabled.
        '';
      };
    } else { })
  ];
}

{ lib, pkgs }:

with lib;

# TODO: add support for commit signing with SSH keys
types.submodule {
  options = {
    package = mkPackageOption pkgs "gnupg" { } // {
      description = ''
        Which program to use for GPG commit signing.
      '';
    };

    signingKey = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "EC6624FA72B9487E";
      description = ''
        GPG private key to sign commits.
      '';
    };

    signCommits = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Enable GPG commit signature by default.
      '';
    };

    signTags = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Enable GPG tag signature by default.
      '';
    };
  };
}

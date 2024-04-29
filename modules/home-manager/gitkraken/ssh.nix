{ lib }:

with lib;

types.submodule {
  options = {
    useLocalAgent = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Use local SSH agent instead of defining SSH key to use.
      '';
    };

    privateKey = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = ''
        Path to the SSH private key file to use.
      '';
    };

    publicKey = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = ''
        Path to the SSH public key file to use.
      '';
    };
  };
}

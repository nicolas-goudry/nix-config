{ lib }:

with lib;

types.submodule {
  options = {
    email = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "email@example.com";
      description = ''
        Email to use as commit author email.
      '';
    };

    name = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "John Doe";
      description = ''
        Name to use as commit author name.
      '';
    };
  };
}

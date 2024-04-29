{ lib }:

with lib;

types.submodule {
  options = {
    diff = mkOption {
      type = types.enum [
        "none"
        "use-configured-merge-tool"
        "git-config"
        "araxis-merge"
        "beyond-compare"
        "file-merge"
        "kaleidoscope"
        "kdiff"
        "p4merge"
      ];
      default = "use-configured-merge-tool";
      description = ''
        Set the preferred external diff tool. This option will not
        install the selected tool.
      '';
    };

    editor = mkOption {
      type = types.enum [
        "none"
        "Atom"
        "VS Code"
        "Sublime Text"
        "Intellij Idea CE"
        "Intellij Idea"
      ];
      default = "none";
      description = ''
        Set the preferred external code/text editor. This option
        will not install the selected editor.
      '';
    };

    merge = mkOption {
      type = types.enum [
        "none"
        "git-config"
        "araxis-merge"
        "beyond-compare"
        "file-merge"
        "kaleidoscope"
        "kdiff"
        "p4merge"
      ];
      default = "git-config";
      description = ''
        Set the preferred external merge tool. This option will not
        install the selected tool.
      '';
    };

    terminal = {
      default = mkOption {
        type = types.enum [
          "none"
          "custom"
          "gitkraken"
        ];
        default = "none";
        description = ''
          Set the preferred terminal. When `gitkraken` is selected, the
          bundled GitKraken terminal will be used. When `custom` is
          selected, the package defined by `tools.terminal.package` will
          be installed and used.
        '';
      };

      package = mkOption {
        type = types.nullOr types.package;
        default = null;
        example = literalExpression "pkgs.alacritty";
        description = ''
          Custom terminal package to use. Must be defined only when
          `tools.terminal.default` is set to `custom`.
        '';
      };

      bin = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "alacritty";
        description = ''
          Custom terminal binary name. Defaults to
          `''${tools.terminal.package.pname}`. Will be prepended by the
          Nix store binary path of the package.
        '';
      };

      extraOptions = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = [
          "--option cursor.style='Beam'"
          "--title 'Alacritty - GitKraken'"
        ];
        description = ''
          Extra options passed to the custom terminal.
        '';
      };
    };
  };
}

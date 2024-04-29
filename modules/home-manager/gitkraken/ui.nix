{ lib }:

with lib;

mode:

assert (mode == "app" || mode == "profile");

types.submodule {
  options = attrsets.mergeAttrsList [
    {
      cli = {
        autocomplete = {
          enable = mkOption {
            type = types.bool;
            default = true;
            description = ''
              Enable autocomplete suggestions.
            '';
          };

          tabBehavior = mkOption {
            type = types.nullOr (types.enum [ "enter" "ignore" "navigation" ]);
            default = "ignore";
            description = ''
              Behavior of the tab key in the integrated terminal when
              autocomplete is enabled. When set to `enter`, the highlighted
              suggestion will be entered. When set to `navigation`, the next
              suggestion will be selected. When set to `ignore`, the tab key
              will be sent to the shell.
            '';
          };
        };

        cursor = mkOption {
          type = types.enum [ "bar" "block" "underline" ];
          default = "block";
          description = ''
            Style of the cursor in the integrated terminal.
          '';
        };

        defaultPath = mkOption {
          type = types.nullOr types.path;
          default = null;
          example = literalExpression "\${config.home.homeDirectory}";
          description = ''
            Default directory to open terminal tabs into.
          '';
        };

        fontFamily = mkOption {
          type = types.nullOr types.str;
          default = null;
          example = "Liberation Mono";
          description = ''
            Font family to use in the integrated terminal.
          '';
        };

        fontSize = mkOption {
          type = types.int;
          default = 12;
          description = ''
            Font size to use in the integrated terminal.
          '';
        };

        lineHeight = mkOption {
          type = types.int;
          default = 1;
          description = ''
            Line height in the integrated terminal.
          '';
        };

        graph = {
          enable = mkOption {
            type = types.bool;
            default = true;
            description = ''
              Show graph panel by default. This setting only affects
              terminal tabs when the current directory is a repository.
            '';
          };

          position = mkOption {
            type = types.nullOr (types.enum [ "bottom" "left" "right" "top" ]);
            default = "bottom";
            description = ''
              Default graph panel position. This setting only affects
              terminal tabs when the current directory is a repository.
            '';
          };
        };
      };

      editor = {
        eol = mkOption {
          type = types.enum [ "CRLF" "LF" ];
          default = "LF";
          description = ''
            End of line character to use in the editor.
          '';
        };

        fontFamily = mkOption {
          type = types.nullOr types.str;
          default = null;
          example = "Liberation Mono";
          description = ''
            Font family to use in the editor.
          '';
        };

        fontSize = mkOption {
          type = types.int;
          default = 12;
          description = ''
            Font size to use in the editor.
          '';
        };

        showLineNumbers = mkOption {
          type = types.bool;
          default = true;
          description = ''
            Show line numbers in the editor.
          '';
        };

        syntaxHighlighting = mkOption {
          type = types.bool;
          default = true;
          description = ''
            Enable syntax highlighting in the editor.
          '';
        };

        tabSize = mkOption {
          type = types.int;
          default = 4;
          description = ''
            Size of the indentation in the editor.
          '';
        };

        wrap = mkOption {
          type = types.bool;
          default = false;
          description = ''
            Enable word wrap in the editor.
          '';
        };
      };

      theme = mkOption {
        type = types.enum [
          "light"
          "light-high-contrast"
          "dark"
          "dark-high-contrast"
          "system"
        ];
        default = "system";
        example = "dark";
        description = ''
          UI theme.
        '';
      };
    }
    (if mode == "app" then {
      enableToolbarLabels = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Show toolbar icon labels.
        '';
      };

      hideWorkspaceTab = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Hide workspace tab when closed.
        '';
      };

      showProjectBreadcrumb = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Show workspace breadcrumb in toolbar.
        '';
      };
    } else { })
  ];
}

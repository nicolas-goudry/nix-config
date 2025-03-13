{ lib }:

with lib;

mode:

assert (mode == "app" || mode == "profile");

types.submodule {
  options = attrsets.mergeAttrsList [
    {
      highlightRowsOnRefHover = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Highlight associated rows when hovering over a branch.
        '';
      };

      showAuthor = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Show commit author.
        '';
      };

      showDatetime = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Show commit date/time.
        '';
      };

      showDescription = mkOption {
        type = types.nullOr (
          types.enum [
            "always"
            "hover"
            "never"
          ]
        );
        default = "always";
        description = ''
          Show commit description.
        '';
      };

      showGhostRefsOnHover = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Show ghost branch/tag when hovering over or selecting a
          commit.
        '';
      };

      showMessage = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Show commit message.
        '';
      };

      showRefs = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Show branches and tags.
        '';
      };

      showSha = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Show commit SHA.
        '';
      };

      showTree = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Show commit tree.
        '';
      };

      useAuthorInitials = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Use author initials instead of avatars.
        '';
      };

      useGenericRemoteIcon = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Use generic remote icon instead of hosting service icon.
        '';
      };
    }
    (
      if mode == "app" then
        {
          lazy = mkOption {
            type = types.bool;
            default = true;
            description = ''
              Enable commits lazy loading. Additional commits will be
              loaded if the earliest commit in the graph is reached.
            '';
          };

          max = mkOption {
            type = types.addCheck types.ints.positive (x: x >= 500);
            default = 2000;
            description = ''
              Maximum number of commits to show in the commit graph.
              Lower counts may help improve performance. Minimum value is
              500.
            '';
          };

          showAll = mkOption {
            type = types.bool;
            default = false;
            description = ''
              Always show all commits in repository. This setting may
              cause performance issue with large repositories.
            '';
          };
        }
      else
        { }
    )
  ];
}

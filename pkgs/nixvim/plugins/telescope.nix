_:

let
  mode = [ "n" "v" ];
in
{
  opts = {
    enable = true;
  };

  rootOpts = {
    # Set custom behavior for dropdown theme:
    # - use 80% of window width
    # - use all window height
    # - display preview at bottom
    # ┌──────────────────────────────────────────────────┐
    # │    ┌────────────────────────────────────────┐    │
    # │    │                 Prompt                 │    │
    # │    ├────────────────────────────────────────┤    │
    # │    │                 Result                 │    │
    # │    │                 Result                 │    │
    # │    └────────────────────────────────────────┘    │
    # │    ┌────────────────────────────────────────┐    │
    # │    │                 Preview                │    │
    # │    │                 Preview                │    │
    # │    │                 Preview                │    │
    # │    │                 Preview                │    │
    # │    │                 Preview                │    │
    # │    │                 Preview                │    │
    # │    └────────────────────────────────────────┘    │
    # └──────────────────────────────────────────────────┘
    extraConfigLuaPre = ''
      local TelescopeWithTheme = function(tfn)
        local theme = require("telescope.themes").get_dropdown({
          layout_config = {
            anchor = "N",
            mirror = true,
            width = 0.8,
          }
        })
        require("telescope.builtin")[tfn](theme)
      end
    '';

    # Use root keymaps to allow usage of custom TelescopeWithTheme function
    keymaps = [
      # List files in current working directory
      {
        inherit mode;
        key = "<leader>ff";
        action = "function() TelescopeWithTheme('find_files') end";
        lua = true;
        options.desc = "Find files";
      }
      # List open buffers in current instance
      {
        inherit mode;
        key = "<leader>fb";
        action = "function() TelescopeWithTheme('buffers') end";
        lua = true;
        options.desc = "Find buffers";
      }
      # Search in current working directory
      {
        inherit mode;
        key = "<leader>fg";
        action = "function() TelescopeWithTheme('live_grep') end";
        lua = true;
        options.desc = "Grep files";
      }
      # Search for current string/selection in current working directory
      {
        inherit mode;
        key = "<leader>fs";
        action = "function() TelescopeWithTheme('grep_string') end";
        lua = true;
        options.desc = "Find word under cursor";
      }
      # List LSP references for word under cursor
      {
        key = "gD";
        action = "function() TelescopeWithTheme('lsp_references') end";
        lua = true;
        mode = "n";
        options.desc = "Find references of word under cursor";
      }
    ];
  };
}

# homepage: https://github.com/nvim-neo-tree/neo-tree.nvim
# nixvim doc: https://nix-community.github.io/nixvim/plugins/neo-tree/index.html
# defaults options: https://github.com/nvim-neo-tree/neo-tree.nvim/blob/main/lua/neo-tree/defaults.lua
_:

{
  opts = {
    enable = true;

    # Automatically clean up broken neo-tree buffers saved in sessions
    autoCleanAfterSessionRestore = true;

    # Close Neo-tree if it is the last window left in the tab
    closeIfLastWindow = true;

    # Extra options not exposed by the plugin
    extraOptions = {
      # Custom functions (taken from AstroNvim)
      commands = {
        # Focus first directory child item or open directory
        child_or_open.__raw = ''
          function(state)
            local node = state.tree:get_node()
            if node:has_children() then
              if not node:is_expanded() then -- if unexpanded, expand
                state.commands.toggle_node(state)
              else -- if expanded and has children, select the next child
                if node.type == "file" then
                  state.commands.open(state)
                else
                  require("neo-tree.ui.renderer").focus_node(state, node:get_child_ids()[1])
                end
              end
            else -- if has no children
              state.commands.open(state)
            end
          end
        '';

        find_in_dir.__raw = ''
          function(state)
            local node = state.tree:get_node()
            local path = node.type == "file" and node:get_parent_id() or node:get_id()
            TelescopeWithTheme('find_files', { cwd = path })
          end
        '';

        # Focus parent directory of currently focused item or close directory
        parent_or_close.__raw = ''
          function(state)
            local node = state.tree:get_node()
            if node:has_children() and node:is_expanded() then
              state.commands.toggle_node(state)
            else
              require("neo-tree.ui.renderer").focus_node(state, node:get_parent_id())
            end
          end
        '';
      };

      window = {
        # Keymaps for filter popup window in fuzzy finder mode (ie. "/")
        fuzzy_finder_mappings = {
          "<C-J>" = "move_cursor_down";
          "<C-K>" = "move_cursor_up";
        };

        # Keymaps when neotree window is focused
        mappings = {
          "[b" = "prev_source";
          "]b" = "next_source";

          # Disable default behavior to toggle node on Space keypress
          "<Space>".__raw = "false";

          # See extraOptions.commands for details on following keymaps
          h = "parent_or_close";
          l = "child_or_open";
          F = "find_in_dir";
        };
      };
    };

    filesystem = {
      # Find and focus file in active buffer
      followCurrentFile.enabled = true;

      # Open neotree "fullscreen" when opening a directory
      hijackNetrwBehavior = "open_current";
    };

    # Sources tabs
    sourceSelector = {
      # Label position
      contentLayout.__raw = "'center'";

      # Tabs separator
      separator = "";

      # Show tabs on winbar
      winbar = true;

      # Sources to show and their labels
      sources = [
        {
          displayName = " Files";
          source = "filesystem";
        }
        {
          displayName = "󰈙 Bufs";
          source = "buffers";
        }
        {
          displayName = "󰊢 Git";
          source = "git_status";
        }
      ];
    };
  };

  rootOpts = {
    autoGroups.neotree = {};

    # Custom autocommands (taken from AstroNvim)
    autoCmd = [
      {
        desc = "Open explorer on startup with directory";
        event = "BufEnter";
        group = "neotree";

        callback.__raw = ''
          function()
            if package.loaded["neo-tree"] then
              return true
            else
              local stats = vim.loop.fs_stat(vim.api.nvim_buf_get_name(0))
              if stats and stats.type == "directory" then
                return true
              end
            end
          end
        '';
      }
      {
        desc = "Refresh explorer sources when closing lazygit";
        event = "TermClose";
        group = "neotree";
        pattern = "*lazygit*";

        callback.__raw = ''
          function()
            local manager_avail, manager = pcall(require, "neo-tree.sources.manager")
            if manager_avail then
              for _, source in ipairs { "filesystem", "git_status", "document_symbols" } do
                local module = "neo-tree.sources." .. source
                if package.loaded[module] then manager.refresh(require(module).name) end
              end
            end
          end
        '';
      }
    ];

    keymaps = [
      {
        key = "<leader>e";
        action = "<cmd>Neotree toggle<cr>";
        options.desc = "Toggle explorer";
      }
      {
        key = "<leader>o";
        options.desc = "Toggle explorer focus";

        action.__raw = ''
          function()
            if vim.bo.filetype == "neo-tree" then
              vim.cmd.wincmd "p"
            else
              vim.cmd.Neotree "focus"
            end
          end
        '';
      }
    ];
  };
}

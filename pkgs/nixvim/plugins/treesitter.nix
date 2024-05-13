_:

{
  opts = {
    # Enable treesitter syntax highlighting
    enable = true;

    # Enable treesitter based folding
    # By default, folds are closed, set foldenable to false to prevent this
    # zc: close fold
    # zo: open fold
    # zi: toggle all untouched folds
    folding = true;

    # Enable treesitter based indentation (use '=' to auto-indent)
    indent = true;

    # Enable incremental selection
    # Keymaps are defined as global nixvim keymaps
    incrementalSelection.enable = true;
  };

  rootOpts = {
    # Prevent folding on file open
    opts.foldenable = false;

    # Workaround for setting descriptions to treesitter incremental selection keymaps
    # See https://github.com/nix-community/nixvim/issues/1506
    keymaps = [
      {
        mode = "n";
        key = "<leader>ss";
        action = "function() require('nvim-treesitter.incremental_selection').init_selection() end";
        lua = true;
        options.desc = "Start incremental selection";
      }
      {
        mode = "v";
        key = "<leader>sd";
        action = "function() require('nvim-treesitter.incremental_selection').node_decremental() end";
        lua = true;
        options.desc = "Decrement selection";
      }
      {
        mode = "v";
        key = "<leader>si";
        action = "function() require('nvim-treesitter.incremental_selection').node_incremental() end";
        lua = true;
        options.desc = "Increment selection by node";
      }
      {
        mode = "v";
        key = "<leader>sc";
        action = "function() require('nvim-treesitter.incremental_selection').scope_incremental() end";
        lua = true;
        options.desc = "Increment selection by scope";
      }
    ];

    # Treesitter textobjects configuration
    plugins.treesitter-textobjects = {
      enable = true;

      # Text objects selection
      select = {
        enable = true;

        # Automatically jump to next textobjects, ie. if a keymap is pressed
        # while the cursor is not under a textobject, the next relevant
        # textobject will be used as "source", similar to the default nvim
        # behavior
        lookahead = true;

        keymaps = {
          oc = {
            query = "@class.outer";
            desc = "Select outer class";
          };

          "if" = {
            query = "@function.inner";
            desc = "Select inner function";
          };

          of = {
            query = "@function.outer";
            desc = "Select outer function";
          };

          ip = {
            query = "@parameter.inner";
            desc = "Select inner parameter";
          };

          op = {
            query = "@parameter.outer";
            desc = "Select outer parameter";
          };

          ii = {
            query = "@conditional.inner";
            desc = "Select inner if condition";
          };

          oi = {
            query = "@conditional.outer";
            desc = "Select outer if condition";
          };
        };
      };
    };
  };
}

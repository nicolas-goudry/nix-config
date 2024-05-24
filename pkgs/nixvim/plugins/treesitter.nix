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
    # Enable catppuccin colors
    # https://github.com/catppuccin/nvim/blob/main/lua/catppuccin/groups/integrations/treesitter.lua
    colorschemes.catppuccin.settings.integrations.treesitter = true;

    keymaps = [
      {
        mode = [ "n" "x" "o" ];
        key = ",";
        action = "function() require('nvim-treesitter.textobjects.repeatable_move').repeat_last_move() end";
        lua = true;
        options.desc = "Repeat last move";
      }
      {
        mode = [ "n" "x" "o" ];
        key = ";";
        action = "function() require('nvim-treesitter.textobjects.repeatable_move').repeat_last_move_opposite() end";
        lua = true;
        options.desc = "Repeat last move in the opposite direction";
      }
      # Workaround for setting descriptions to treesitter incremental selection keymaps
      # See https://github.com/nix-community/nixvim/issues/1506
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

      # Jump across text objects
      move = {
        enable = true;
        setJumps = true;

        gotoNextStart = {
          "]k" = { query = "@block.outer"; desc = "Next block start"; };
          "]f" = { query = "@function.outer"; desc = "Next function start"; };
          "]a" = { query = "@parameter.inner"; desc = "Next argument start"; };
        };

        gotoNextEnd = {
          "]K" = { query = "@block.outer"; desc = "Next block end"; };
          "]F" = { query = "@function.outer"; desc = "Next function end"; };
          "]A" = { query = "@parameter.inner"; desc = "Next argument end"; };
        };

        gotoPreviousStart = {
          "[k" = { query = "@block.outer"; desc = "Previous block start"; };
          "[f" = { query = "@function.outer"; desc = "Previous function start"; };
          "[a" = { query = "@parameter.inner"; desc = "Previous argument start"; };
        };

        gotoPreviousEnd = {
          "[K" = { query = "@block.outer"; desc = "Previous block end"; };
          "[F" = { query = "@function.outer"; desc = "Previous function end"; };
          "[A" = { query = "@parameter.inner"; desc = "Previous argument end"; };
        };
      };

      # Select text objects
      select = {
        enable = true;

        # Automatically jump to next textobjects, ie. if a keymap is pressed
        # while the cursor is not under a textobject, the next relevant
        # textobject will be used as "source", similar to the default nvim
        # behavior
        lookahead = true;

        keymaps = {
          ak = { query = "@block.outer"; desc = "around block"; };
          ik = { query = "@block.inner"; desc = "inside block"; };
          ac = { query = "@class.outer"; desc = "around class"; };
          ic = { query = "@class.inner"; desc = "inside class"; };
          "a?" = { query = "@conditional.outer"; desc = "around conditional"; };
          "i?" = { query = "@conditional.inner"; desc = "inside conditional"; };
          af = { query = "@function.outer"; desc = "around function"; };
          "if" = { query = "@function.inner"; desc = "inside function"; };
          ao = { query = "@loop.outer"; desc = "around loop"; };
          io = { query = "@loop.inner"; desc = "inside loop"; };
          aa = { query = "@parameter.outer"; desc = "around argument"; };
          ia = { query = "@parameter.inner"; desc = "inside argument"; };
        };
      };

      # Swap nodes with next/previous one
      swap = {
        enable = true;

        swapNext = {
          ">K" = { query = "@block.outer"; desc = "Swap next block"; };
          ">F" = { query = "@function.outer"; desc = "Swap next function"; };
          ">A" = { query = "@parameter.inner"; desc = "Swap next argument"; };
        };

        swapPrevious = {
          "<K" = { query = "@block.outer"; desc = "Swap previous block"; };
          "<F" = { query = "@function.outer"; desc = "Swap previous function"; };
          "<A" = { query = "@parameter.inner"; desc = "Swap previous argument"; };
        };
      };
    };
  };
}

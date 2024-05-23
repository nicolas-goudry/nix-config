{ pkgs, ... }:

{
  imports = [
    ./plugins
  ];

  config = {
    # Needed for telescope live grep
    extraPackages = [ pkgs.ripgrep ];

    # Use <Space> as leader key
    globals.mapleader = " ";

    # Set 'vi' and 'vim' aliases to nixvim
    viAlias = true;
    vimAlias = true;

    # Setup clipboard support
    clipboard = {
      # Use xsel as clipboard provider
      providers.xsel.enable = true;

      # Sync system clipboard
      register = "unnamedplus";
    };

    # Use catppuccin mocha variant
    colorschemes.catppuccin = {
      enable = true;

      settings = {
        flavour = "mocha";

        # Needed to keep terminal transparency, if any
        transparent_background = true;
      };
    };

    keymaps = let
      forceWrite = {
        action = "<cmd>silent! update! | redraw<cr>";
        options.desc = "Force write";
      };
    in [
      {
        key = "<leader>n";
        action = "<cmd>enew<cr>";
        options.desc = "New file";
      }
      {
        inherit (forceWrite) action options;
        key = "<c-s>";
      }
      {
        inherit (forceWrite) options;
        mode = [ "i" "x" ];
        key = "<c-s>";
        action = "<esc>${forceWrite.action}";
      }
      {
        key = "|";
        action = "<cmd>vsplit<cr>";
        options.desc = "Split vertically";
      }
      {
        key = "\\";
        action = "<cmd>split<cr>";
        options.desc = "Split horizontally";
      }
    ];

    # Neovim options
    # Use :options to get the list of all options
    # Use :h <option> to load help for given <option>
    opts = {
      # Hide command line unless needed
      cmdheight = 0;

      # Insert mode completion options
      completeopt = [ "menu" "menuone" "noselect" ];

      # Copy previous indentation on autoindenting
      copyindent = true;

      # Highlight current line
      cursorline = true;

      # Expand <Tab> to spaces
      expandtab = true;

      # Enable fold with all code unfolded
      foldcolumn = "1";
      foldenable = true;
      foldlevel = 99;
      foldlevelstart = 99;

      # Ignore case in search patterns
      ignorecase = true;

      # Show substitution preview in split window
      inccommand = "split";

      # Infer casing on word completion
      infercase = true;

      # Enable list mode
      list = true;

      # Set custom strings for list mode
      # - tabulations are shown as ‒▶
      # - trailing spaces are shown as ·
      # - multiple non-leading consecutive spaces are shown as bullets (·)
      # - non-breakable spaces are shown as ⎕
      listchars = "tab:‒▶,trail:·,multispace:·,lead: ,nbsp:⎕";

      # Show line numbers
      number = true;

      # Preserve indentation as much as possible
      preserveindent = true;

      # Height of the popup menu
      pumheight = 10;

      # Display line numbers relative to current line
      relativenumber = true;

      # Minimal number of lines to keep around the cursor
      # This has the effect to move the view along with current line
      #scrolloff = 999;

      # Number of spaces to use for indentation
      shiftwidth = 2;

      # Always show tabline (TODO: use with heirline?)
      #showtabline = 2;

      # Show signs instead of number in gutter
      signcolumn = "number";

      # Override ignorecase if search pattern contains uppercase characters
      smartcase = true;

      # Number of spaces input on <Tab>
      softtabstop = 2;

      # Open horizontal split below (:split)
      splitbelow = true;

      # Open vertical split to the right (:vsplit)
      splitright = true;

      # Number of spaces to represent a <Tab>
      tabstop = 2;

      # Enables 24-bit RGB color
      termguicolors = true;

      # Shorter timeout duration
      timeoutlen = 500;

      # Set window title to the filename
      title = true;

      # Save undo history to undo file (in $XDG_STATE_HOME/nvim/undo)
      undofile = true;

      # Enable virtual edit in visual block mode
      # This has the effect of selecting empty cells beyond lines boundaries
      virtualedit = "block";

      # Disable line wrapping
      wrap = false;
    };
  };
}

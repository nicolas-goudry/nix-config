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

    # Neovim options
    # Use :options to get the list of all options
    # Use :h <option> to load help for given <option>
    opts = {
      # Expand <Tab> to spaces
      expandtab = true;

      # Ignore case in search patterns
      ignorecase = true;

      # Show substitution preview in split window
      inccommand = "split";

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

      # Display line numbers relative to current line
      relativenumber = true;

      # Minimal number of lines to keep around the cursor
      # This has the effect to move the view along with current line
      #scrolloff = 999;

      # Number of spaces to use for indentation
      shiftwidth = 2;

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

      # Enable virtual edit in visual block mode
      # This has the effect of selecting empty cells beyond lines boundaries
      virtualedit = "block";

      # Disable line wrapping (TODO: keep?)
      wrap = false;
    };
  };
}

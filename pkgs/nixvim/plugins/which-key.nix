# homepage: https://github.com/folke/which-key.nvim
# nixvim doc: https://nix-community.github.io/nixvim/plugins/which-key/index.html
# defaults options: https://github.com/folke/which-key.nvim/blob/main/lua/which-key/config.lua
_:

{
  opts = {
    enable = true;
    window.border = "single";

    disable.filetypes = [
      "TelescopePrompt"
      "neo-tree"
      "neo-tree-popup"
    ];
  };

  rootOpts.colorschemes.catppuccin.settings.integrations.which_key = true;
}

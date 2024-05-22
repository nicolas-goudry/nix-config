{ libn, pkgs, ... }:

let
  header = {
    type = "text";

    opts = {
      hl = "AlphaHeader";
      position = "center";
    };

    val = [
      "  ________  ____   ____.___   _____   "
      " /  _____/  \\   \\ /   /|   | /     \\  "
      "/   \\  ___   \\   Y   / |   |/  \\ /  \\ "
      "\\    \\_\\  \\   \\     /  |   /    Y    \\"
      " \\______  / /\\ \\___/   |___\\____|__  /"
      "        \\/  \\/                     \\/ "
    ];
  };

  buttons = {
    type = "group";
    opts.spacing = 1;

    val = [
      { __raw = "alpha_button('LDR n  ', '  New File')"; }
      { __raw = "alpha_button('LDR e  ', '  Explorer')"; }
      { __raw = "alpha_button('LDR f f', '  Find File')"; }
      { __raw = "alpha_button('LDR f o', '󰈙  Recents')"; }
      { __raw = "alpha_button('LDR f g', '󰈭  Live Grep')"; }
    ];
  };

  footer = {
    type = "text";
    val.__raw = "require('alpha.fortune')()";

    opts = {
      hl = "AlphaFooter";
      position = "center";
    };
  };

  layout = [
    {
      type = "padding";
      val.__raw = "vim.fn.max { 2, vim.fn.floor(vim.fn.winheight(0) * 0.2) }";
    }
    header
    { type = "padding"; val = 5; }
    buttons
    { type = "padding"; val = 3; }
    footer
  ];
in
{
  extra = {
    packages = with pkgs.vimPlugins; [
      alpha-nvim
      nvim-web-devicons
    ];

    config = ''
      local alpha_leader = "LDR"

      function alpha_button(shortcut, desc, keybind, keybind_opts)
        local sc = shortcut:gsub("%s", ""):gsub(alpha_leader, "<leader>")

        local real_leader = vim.g.mapleader
        if real_leader == " " then real_leader = "SPC" end

        local opts = {
          position = "center",
          shortcut = shortcut:gsub(alpha_leader, real_leader),
          cursor = -2,
          width = 36,
          align_shortcut = "right",
          hl = "AlphaButtons",
          hl_shortcut = "AlphaShortcut",
        }

        if keybind then
          keybind_opts = if_nil(keybind_opts, { noremap = true, silent = true, nowait = true, desc = desc })
          opts.keymap = { "n", sc, keybind, keybind_opts }
        end

        local function on_press()
          local key = vim.api.nvim_replace_termcodes(keybind or sc .. "<ignore>", true, false, true)
          vim.api.nvim_feedkeys(key, "t", false)
        end

        return {
          type = "button",
          val = desc,
          on_press = on_press,
          opts = opts,
        }
      end

      require("alpha").setup({
        layout = ${libn.helpers.toLuaObject layout},
      })
    '';
  };

  rootOpts = {
    colorschemes.catppuccin.settings = {
      integrations.alpha = true;

      custom_highlights = ''
        function(colors)
          return {
            AlphaHeader = { fg = colors.red },
          }
        end
      '';
    };

    keymaps = [
      {
        key = "<leader>h";
        options.desc = "Home screen";

        action.__raw = ''
          function()
            local wins = vim.api.nvim_tabpage_list_wins(0)
            if #wins > 1 and vim.bo[vim.api.nvim_win_get_buf(wins[1])].filetype == "neo-tree" then
              vim.fn.win_gotoid(wins[2])
            end
            require("alpha").start(false)
          end
        '';
      }
    ];
  };
}

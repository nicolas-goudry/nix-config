_:

{
  imports = [
    ./plugins
  ];

  config = {
    # Set 'vi' and 'vim' aliases to nixvim
    viAlias = true;
    vimAlias = true;

    # Neovim options
    # Use :options to get the list of all options
    # Use :h <option> to load help for given <option>
    opts = {
      # Expand <Tab> to spaces
      expandtab = true;

      # Number of spaces to use for indentation
      shiftwidth = 2;

      # Number of spaces input on <Tab>
      softtabstop = 2;

      # Number of spaces to represent a <Tab>
      tabstop = 2;
    };
  };
}

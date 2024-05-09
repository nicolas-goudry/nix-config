# This file will load all plugins defined in the current directory (plugins)
# and load their content in the 'plugins' nixvim attribute.
# Each plugin file must have the same name as the plugin attribute name
# expected by nixvim (ie. 'telescope.nix' for 'plugins.telescope').
# Each plugin file must export a lambda, which is called with an attrset
# containing nixpkgs library as 'lib'. Plugins may or may not use it.
# Each plugin lambda must return an attrset with at least the 'opts' attribute,
# this attribute is the plugin options as expected by nixvim. Additionally, a
# 'rootOpts' can be returned along with 'opts', this attribute is extra options
# to set to the root nixvim options. For example, this allows to set keymaps
# for plugins that do not have an internal option to set keymaps.

{ lib, ... }:

let
  definitions = lib.attrNames (
    lib.filterAttrs
      (filename: kind: (kind == "regular" || kind == "directory") && filename != "default.nix")
      (builtins.readDir ./.)
  );
in lib.mkMerge (
  map (file:
    let
      pluginName = lib.elemAt (lib.splitString "." file) 0;
      plugin = import ./${file} { inherit lib; };
    in lib.mkMerge [
      {
        plugins.${pluginName} = plugin.opts;
      }
      (if plugin ? rootOpts then plugin.rootOpts else { })
    ]
  ) definitions
)

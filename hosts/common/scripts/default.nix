{ lib, ... }:

let
  currentDir = ./.;
  importDirectory = name: import (currentDir + "/${name}");
  directories = lib.filterAttrs (
    name: type: type == "directory" && name != "_template"
  ) builtins.readDir currentDir;
in
{
  imports = lib.mapAttrsToList (name: _: importDirectory name) directories;
}

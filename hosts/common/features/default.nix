{ config, lib, ... }@args:

with lib;

let
  rootModuleName = "featx";
  baseDir = ./.;

  importModulesRecursively =
    basePath: modulePath:
    let
      files = filterAttrs (n: _: (builtins.baseNameOf n) != "default.nix") (builtins.readDir basePath);
      entries = attrNames files;

      processEntry =
        name:
        let
          importPath = "${basePath}/${name}";
        in
        if files.${name} == "directory" then
          {
            "${name}" = importModulesRecursively importPath (modulePath ++ [ name ]);
          }
        else if hasSuffix ".nix" name then
          let
            moduleName = removeSuffix ".nix" name;
            module = import importPath (
              args // { cfg = attrByPath (modulePath ++ [ moduleName ]) { } config; }
            );
          in
          {
            "${moduleName}" = {
              options = mkOption {
                type = types.submodule {
                  options = optionalAttrs (module ? options) module.options;
                };
                default = { };
              };

              config = optionalAttrs (module ? "config") module.config;
            };
          }
        else
          { }; # Ignore non-Nix files

      processedEntries = map processEntry entries;
      mergedEntries = foldl' (a: b: a // b) { } processedEntries;
    in
    {
      options = mkOption {
        type = types.submodule {
          options = mapAttrs (_: v: v.options) mergedEntries;
        };
        default = { };
      };

      config = foldl' (acc: v: acc // v.config) { } (attrValues mergedEntries);
    };

  modulesTree = importModulesRecursively baseDir [ rootModuleName ];

in
{
  options.${rootModuleName} = modulesTree.options;
  config = modulesTree.config;
}

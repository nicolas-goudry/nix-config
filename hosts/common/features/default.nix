# Recursive module loading system that automatically imports and structures Nix modules from a directory hierarchy
{ config, lib, ... }@args:

with lib;

let
  # Root module from which all loaded modules will be available
  rootModuleName = "featx";

  # Base directory from which modules will be loaded
  baseDir = ./.;

  /*
    Walk through directories to create a nested option structure that mirrors the filesystem hierarchy

    Parameters:
    - basePath: current directory being processed
    - modulePath: list of path segments to keep track of the current module's nested option path

    Returns: attribute set containing two main attributes:
    - options: options structure for the imported modules
    - config: combined configuration from all imported modules
  */
  importModulesRecursively =
    basePath: modulePath:
    let
      # Read directory contents, excluding default.nix
      files = filterAttrs (n: _: (builtins.baseNameOf n) != "default.nix") (builtins.readDir basePath);

      # Map of all entries to process (files and directories)
      entries = attrNames files;

      /*
        Process a single entry (file or directory)

        Parameters:
        - name: name of the file or directory to process

        Returns: attribute set containing the processed module structure
      */
      processEntry =
        name:
        let
          # Full path to the current entry
          importPath = "${basePath}/${name}";
        in
        # Recursively process directory and store result in an option named after the directory
        # ie. all files under 'kbd' directory will be exposed under `kbd` option
        if files.${name} == "directory" then
          {
            "${name}" = importModulesRecursively importPath (modulePath ++ [ name ]);
          }
        # Import .nix files as modules
        else if hasSuffix ".nix" name then
          let
            # Human-friendly module name
            moduleName = removeSuffix ".nix" name;

            # Import module while automatically passing down its own configuration values as 'cfg' attribute
            module = import importPath (
              args // { cfg = attrByPath (modulePath ++ [ moduleName ]) { } config; }
            );
          in
          {
            "${moduleName}" = {
              # Options structure for the module
              options = mkOption {
                type = types.submodule {
                  options = optionalAttrs (module ? options) module.options;
                };
                default = { };
              };

              # Include module configuration
              config = optionalAttrs (module ? "config") module.config;
            };
          }
        else
          # Ignore non-Nix files
          { };

      # Process all entries in the current directory
      processedEntries = map processEntry entries;

      # Merge all processed entries into a single attribute set of module options and configurations
      mergedEntries = foldl' (a: b: a // b) { } processedEntries;
    in
    {
      # Create nested options structure for current level
      options = mkOption {
        type = types.submodule {
          options = mapAttrs (_: v: v.options) mergedEntries;
        };
        default = { };
      };

      # Merge configurations from all modules at current level
      config = foldl' (acc: v: acc // v.config) { } (attrValues mergedEntries);
    };

  # Generate the complete modules tree starting from the base directory
  modulesTree = importModulesRecursively baseDir [ rootModuleName ];
in
{
  # Export the merged configurations
  inherit (modulesTree) config;

  # Export the complete options structure under the root module name
  options.${rootModuleName} = modulesTree.options;
}

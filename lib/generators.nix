{
  inputs,
  lib,
  outputs,
  stateVersion,
  ...
}:

let
  # recurseReadDir: path -> [string]? -> attrset
  #
  # Recursively reads a directory and creates a nested attribute set where:
  # - Keys are the file paths (without .nix extension)
  # - Values are the original file names
  # - Nested directories are represented as nested attribute sets
  #
  # Parameters:
  #   dir: Path to the directory to read
  #   parentPath: Optional list of path segments for nested directories
  #
  # Example:
  #   recurseReadDir ./foo null
  #   => {
  #     "bar" = "bar.nix";
  #     "nested" = {
  #       "baz" = "baz.nix";
  #     };
  #   }
  # :p recurseReadDir ./hosts/common/features null
  recurseReadDir =
    dir: parentPath:
    let
      entries = builtins.readDir dir;
      files = builtins.attrNames entries;
    in
    lib.foldl' (
      flatDirListing: entry:
      let
        fullPath = "${dir}/${entry}";
        newPath = if builtins.isNull parentPath then [ entry ] else parentPath ++ [ entry ];
        attrName = lib.removeSuffix ".nix" entry;
      in
      if entries.${entry} == "directory" then
        lib.recursiveUpdate flatDirListing (recurseReadDir fullPath newPath)
      else if entries.${entry} == "regular" && lib.hasSuffix ".nix" entry then
        if builtins.isNull parentPath then
          lib.recursiveUpdate flatDirListing { ${attrName} = fullPath; }
        else
          lib.recursiveUpdate flatDirListing (lib.setAttrByPath (parentPath ++ [ attrName ]) fullPath)
      else
        flatDirListing
    ) { } files;
in
{
  # Function to generate home-manager configurations
  mkHome =
    {
      username,
      hostname ? "",
      desktop ? null,
      platform ? "x86_64-linux",
    }:
    let
      isISO = builtins.substring 0 4 hostname == "iso-";
      isInstall = !isISO;
      isWorkstation = builtins.isString desktop;
    in
    inputs.home-manager.lib.homeManagerConfiguration {
      # Common home-manager configuration
      modules = [ ../home ];

      # Packages for given platform
      pkgs = inputs.nixpkgs.legacyPackages.${platform};

      extraSpecialArgs = {
        inherit
          desktop
          hostname
          inputs
          isInstall
          isISO
          isWorkstation
          outputs
          platform
          stateVersion
          username
          ;
      };
    };

  # Function to generate NixOS configurations
  mkHost =
    {
      hostname,
      username ? "",
      desktop ? null,
      platform ? "x86_64-linux",
    }:
    let
      isISO = builtins.substring 0 4 hostname == "iso-";
      isInstall = !isISO;
      isWorkstation = builtins.isString desktop;
      cd-dvd =
        if isWorkstation then
          "${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-graphical-base.nix"
        else
          "${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal-new-kernel-no-zfs.nix";
    in
    inputs.nixpkgs.lib.nixosSystem {
      # Common host configuration merged with ISO installer if needed
      modules = [ ../hosts ] ++ (inputs.nixpkgs.lib.optional isISO cd-dvd);

      specialArgs = {
        inherit
          desktop
          hostname
          inputs
          isInstall
          isISO
          isWorkstation
          outputs
          platform
          stateVersion
          username
          ;
      };
    };

  # Function to generate user secrets for a user
  # Example:
  # mkUserSecrets {
  #   sopsFile = ./secrets.yaml;
  #   username = "foo";
  #   secrets = [
  #     name = "mysecret"; # file name
  #     file = "mysecretnewname"; # forced file name
  #     dir = ".secret"; # parent directory, relative to user home
  #     path = "/home/root"; # forced full path to file
  #     mode = "0400"; # permissions in octal mode
  #     neededForUsers = false; # is secret needed for users (on boot)
  #   ];
  # }
  mkUserSecrets =
    {
      secrets,
      sopsFile,
      username,
    }:
    if username == "" then
      { }
    else
      lib.attrsets.mergeAttrsList (
        lib.forEach secrets (secret: {
          ${secret.name} = {
            inherit sopsFile;

            neededForUsers = if secret ? "neededForUsers" then secret.neededForUsers else false;
            owner = lib.mkIf (!secret ? "neededForUsers") username;
            group = lib.mkIf (!secret ? "neededForUsers") "users";
            mode = if secret ? "mode" then secret.mode else "0400";

            path = lib.mkIf (secret ? "path" || secret ? "dir") (
              if secret ? "path" then
                secret.path
              else
                "/home/${username}/${secret.dir}/${if secret ? "file" then secret.file else secret.name}"
            );
          };
        })
      );

  mkModuleFromDir =
    path:
    { config, lib, ... }@args:
    let
      namespace = baseNameOf path;
      dirTree = recurseReadDir path null;
      submodules = lib.mapAttrsRecursive (
        attrPath: submodulePath:
        let
          submodule = import submodulePath;
        in
        {
          inherit (submodule) mkOptions mkConfig;
          path = lib.remove "default" attrPath;
        }
      ) dirTree;
      collectConfigs =
        attrs:
        let
          handleAttr =
            name: value:
            if builtins.isAttrs value then
              if value ? mkConfig then
                value.mkConfig (lib.attrByPath value.path { } config)
              else
                collectConfigs value
            else
              [ ];
        in
        lib.flatten (lib.mapAttrsToList handleAttr attrs);
      collectOptions =
        attrs:
        let
          handleAttr =
            name: value:
            if builtins.isAttrs value then
              if value ? mkOptions then
                lib.setAttrByPath value.path (
                  lib.mkOption {
                    type = lib.types.submodule {
                      options = value.mkOptions lib;
                    };
                    default = { };
                    description = "Generated options for ${builtins.head value.path}";
                  }
                )
              else
                lib.setAttrByPath [ name ] (
                  lib.mkOption {
                    type = lib.types.submodule {
                      options = collectOptions value;
                    };
                    default = { };
                    description = "Generated options for ${name}";
                  }
                )
            else
              { };
        in
        lib.foldl' lib.recursiveUpdate { } (lib.mapAttrsToList handleAttr attrs);
    in
    {
      imports = collectConfigs submodules;
      options = {
        ${namespace} = lib.mkOption {
          type = lib.types.submodule {
            options = collectOptions submodules;
          };
          default = { };
          description = "Options for ${namespace}";
        };
      };
    };
}

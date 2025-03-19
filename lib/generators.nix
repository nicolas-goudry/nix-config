{
  inputs,
  lib,
  outputs,
  stateVersion,
  ...
}:

{
  # Function to generate home-manager configurations
  mkHome =
    {
      hostname,
      username,
      desktop ? null,
      platform ? "x86_64-linux",
    }:
    let
      isISO = builtins.substring 0 4 hostname == "iso-";
      isInstall = !isISO;
      isWorkstation = builtins.isString desktop;
    in
    inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = inputs.nixpkgs.legacyPackages.${platform};

      extraSpecialArgs = {
        inherit
          inputs
          outputs
          desktop
          hostname
          platform
          username
          stateVersion
          isInstall
          isISO
          isWorkstation
          ;
      };

      # Common home-manager configuration
      modules = [ ../home ];
    };

  # Function to generate NixOS configurations
  mkHost =
    {
      hostname,
      username,
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
      specialArgs = {
        inherit
          inputs
          outputs
          desktop
          hostname
          platform
          username
          stateVersion
          isInstall
          isISO
          isWorkstation
          ;
      };

      # Common host configuration merged with ISO installer if needed
      modules = [ ../hosts ] ++ (inputs.nixpkgs.lib.optional isISO cd-dvd);
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
}

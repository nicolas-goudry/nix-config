{ inputs, ... }:

{
  # Custom packages from the 'pkgs' directory
  additions =
    final: prev:
    let
      localPkgs = prev.lib.packagesFromDirectoryRecursive {
        inherit (prev.pkgs) callPackage;
        directory = ../pkgs;
      };
    in
    localPkgs
    // {
      inherit (inputs.nixkraken.packages.${prev.stdenv.hostPlatform.system}) gitkraken-themes;
      nixvim = inputs.nixvim-config.packages.${prev.stdenv.hostPlatform.system}.default;
      nixvim-lite = inputs.nixvim-config.packages.${prev.stdenv.hostPlatform.system}.lite;
    };

  # Change versions, add patches, set compilation flags, etc...
  # https://wiki.nixos.org/wiki/Overlays
  modifications = final: prev: {
    # example = prev.example.overrideAttrs (oldAttrs: rec {
    # ...
    # });
  };

  # Unstable nixpkgs set through 'pkgs.unstable'
  unstable-packages = final: prev: {
    unstable = import inputs.nixpkgs-unstable {
      inherit (prev.stdenv.hostPlatform) system;
      config.allowUnfree = true;
    };
  };
}

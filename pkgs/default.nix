# Custom packages, that can be defined similarly to ones from nixpkgs
# Build them using 'nix build .#example'

{ lib, callPackage, ... }:

lib.packagesFromDirectoryRecursive {
  inherit callPackage;
  directory = ./.;
}

# Custom packages, that can be defined similarly to ones from nixpkgs
# Build them using 'nix build .#example'

{ disko, pkgs }:

{
  # example = pkgs.callPackage ./example.nix { };
  catppuccin-alacritty = pkgs.callPackage ./catppuccin-alacritty.nix { };
  catppuccin-delta = pkgs.callPackage ./catppuccin-delta.nix { };
  catppuccin-gitkraken = pkgs.callPackage ./catppuccin-gitkraken.nix { };
  install-system = pkgs.writeScriptBin "install-system" (import ../hosts/common/users/nixos/install.nix { inherit disko pkgs; });
  omz-custom-plugins = pkgs.callPackage ./omz-custom-plugins { };
}

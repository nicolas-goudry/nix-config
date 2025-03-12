# Custom packages, that can be defined similarly to ones from nixpkgs
# Build them using 'nix build .#example'

pkgs:

{
  # example = pkgs.callPackage ./example.nix { };
  catppuccin-alacritty = pkgs.callPackage ./catppuccin-themes/alacritty.nix { };
  catppuccin-delta = pkgs.callPackage ./catppuccin-themes/delta.nix { };
  catppuccin-gitkraken = pkgs.callPackage ./catppuccin-themes/gitkraken.nix { };
  omz-custom-plugins = pkgs.callPackage ./omz-custom-plugins { };
}

# Custom packages, that can be defined similarly to ones from nixpkgs
# Build them using 'nix build .#example'

pkgs:

{
  # example = pkgs.callPackage ./example.nix { };
  catppuccin-delta = pkgs.callPackage ./catppuccin-themes/delta.nix { };
  catppuccin-gitkraken = pkgs.callPackage ./catppuccin-themes/gitkraken.nix { };
  kdrive = pkgs.callPackage ./kdrive { };
  omz-custom-plugins = pkgs.callPackage ./omz-custom-plugins { };
}

{ lib, outputs, pkgs, ... }:

{
  home.programs = {
    # Use Alacritty wrapped by NixGL
    alacritty.package = lib.mkForce (outputs.libx.wrapNixGL { pkg = pkgs.unstable.alacritty; });

    git = {
      # Override default git email
      userEmail = lib.mkForce "nicolas.goudry-ext@numspot.com";
    };
  };
}

{ hostname, lib, outputs, pkgs, username, ... }:

{
  home.shellAliases = {
    switch-home = "cd ~/nixstrap && home-manager --extra-experimental-features flakes --extra-experimental-features nix-command switch -b backup --flake .#${username}@${hostname} && cd -";
  };

  programs = {
    alacritty.package = lib.mkForce (outputs.libx.wrapNixGL { pkg = pkgs.unstable.alacritty; });

    git = {
      userEmail = lib.mkForce "nicolas.goudry-ext@numspot.com";
    };
  };
}

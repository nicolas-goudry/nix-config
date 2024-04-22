{ hostname, lib, pkgs, username, ... }:

{
  home.shellAliases = {
    switch-home = "cd ~/nixstrap && home-manager --extra-experimental-features flakes --extra-experimental-features nix-command switch -b backup --flake .#${username}@${hostname} && cd -";
  };

  programs.git = {
    userEmail = lib.mkForce "nicolas.goudry-ext@numspot.com";
  };
}

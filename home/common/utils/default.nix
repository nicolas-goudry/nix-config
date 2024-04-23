{ hostname, pkgs, username, ... }:

let
  fetch-nixstrap = pkgs.writeScriptBin "fetch-nixstrap" ''
    #!${pkgs.stdenv.shell}

    set -euo pipefail

    if ! test -d "''${HOME}/nixstrap"; then
      if test "''${1}" != "ssh"; then
        git clone https://github.com/nicolas-goudry/nix-config "''${HOME}/nixstrap"
      else
        git clone git@github.com:nicolas-goudry/nix-config "''${HOME}/nixstrap"
      fi
    fi

    pushd "''${HOME}/nixstrap"
    git pull origin main
    popd
  '';

  switch-home = pkgs.writeScriptBin "switch-home" ''
    #!${pkgs.stdenv.shell}

    set -euo pipefail

    pushd "''${HOME}/nixstrap" || { echo "nixstrap directory is missing"; exit 1; }
    home-manager switch \
      --extra-experimental-features flakes \
      --extra-experimental-features nix-command \
      --cores $(($(nproc) * 75 / 100)) \
      --flake .#${username}@${hostname} \
      -b backup \
      "$@"
    popd || exit 1
  '';
in
{
  home.packages = [
    fetch-nixstrap
    switch-home
  ];
}

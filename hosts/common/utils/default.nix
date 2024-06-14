{ pkgs, ... }:

let
  fetch-nixstrap = pkgs.writeScriptBin "fetch-nixstrap" ''
    #!${pkgs.stdenv.shell}

    set -euo pipefail

    if ! test -d "$HOME/nixstrap"; then
      if test "$1" != "ssh"; then
        ${pkgs.git}/bin/git clone https://github.com/nicolas-goudry/nix-config "$HOME/nixstrap"
      else
        ${pkgs.git}/bin/git clone git@github.com:nicolas-goudry/nix-config "$HOME/nixstrap"
      fi
    fi

    pushd "$HOME/nixstrap"
    ${pkgs.git}/bin/git pull origin main
    popd
  '';

  switch-home = pkgs.writeScriptBin "switch-home" ''
    #!${pkgs.stdenv.shell}

    set -euo pipefail

    pushd "$HOME/nixstrap" || { ${pkgs.coreutils}/bin/echo "nixstrap directory is missing"; exit 1; }
    ${pkgs.home-manager}/bin/home-manager switch \
      --extra-experimental-features flakes \
      --extra-experimental-features nix-command \
      --cores $(($(${pkgs.coreutils}/bin/nproc) * 75 / 100)) \
      --flake . \
      -b backup \
      "$@"
    popd || exit 1
  '';
in
{
  environment.systemPackages = [
    fetch-nixstrap
    switch-home
  ];
}

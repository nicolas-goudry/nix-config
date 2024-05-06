{ pkgs }:

pkgs.writeScriptBin "gk-decrypt" ''
  #!${pkgs.bash}/bin/bash

  set -euo pipefail

  # Variables
  SCRIPT_NAME="$(basename "$0")"

  # Helper constants
  GK_CONFIG=$HOME/.gitkraken/config

  # Color codes
  NC="\e[0m"
  BOLD="\e[1m"
  DIM="\e[2m"
  RED="\e[0;31m"
  BOLDRED="\e[1;31m"

  # Utility function to output error message
  error() {
    >&2 ${pkgs.coreutils}/bin/echo -e "''${BOLDRED}ERROR:$NC $RED$*$NC"
  }

  # Utility function to exit script with optional error message
  die() {
    if test "$#" -gt 0; then
      error "$*"
    fi

    exit 1
  }

  # Help usage (accepts an argument to prevent script to exit right way)
  usage() {
    ${pkgs.coreutils}/bin/echo
    ${pkgs.coreutils}/bin/echo "Decrypt GitKraken secret file."
    ${pkgs.coreutils}/bin/echo
    ${pkgs.coreutils}/bin/echo -e "''${BOLD}Usage:$NC"
    ${pkgs.coreutils}/bin/echo
    ${pkgs.coreutils}/bin/echo -e "    $DIM\$$NC $SCRIPT_NAME SECRET_FILE"
    ${pkgs.coreutils}/bin/echo
    ${pkgs.coreutils}/bin/echo -e "''${BOLD}Arguments:$NC"
    ${pkgs.coreutils}/bin/echo
    ${pkgs.coreutils}/bin/echo "    SECRET_FILE    Path to the secret file to decrypt"
    ${pkgs.coreutils}/bin/echo

    if test -z "''${1:-}"; then
      exit 0
    fi
  }

  ensure_config() {
    if ! test -r "$GK_CONFIG"; then
      die "config file not found. Is GitKraken installed?"
    fi
  }

  decrypt_secret() {
    ${pkgs.openssl}/bin/openssl enc -aes-256-cbc -md md5 -d -k "$(${pkgs.jq}/bin/jq -r '.appId' $GK_CONFIG)')" -nosalt -in "$SECRET_FILE"
  }

  main() {
    ensure_config
    decrypt_secret
  }

  SECRET_FILE="''${1:-}"

  if test -z "$SECRET_FILE"; then
    error "$SCRIPT_NAME requires a file to decrypt"
    usage
  elif ! test -r "$SECRET_FILE"; then
    die "$SECRET_FILE is not a readable file"
  fi

  main
''

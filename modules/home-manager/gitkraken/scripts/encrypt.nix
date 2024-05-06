{ pkgs }:

pkgs.writeScriptBin "gk-encrypt" ''
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
    ${pkgs.coreutils}/bin/echo "Encrypt GitKraken secret file."
    ${pkgs.coreutils}/bin/echo
    ${pkgs.coreutils}/bin/echo -e "''${BOLD}Usage:$NC"
    ${pkgs.coreutils}/bin/echo
    ${pkgs.coreutils}/bin/echo -e "    $DIM\$$NC $SCRIPT_NAME DATA DESTINATION"
    ${pkgs.coreutils}/bin/echo
    ${pkgs.coreutils}/bin/echo -e "''${BOLD}Arguments:$NC"
    ${pkgs.coreutils}/bin/echo
    ${pkgs.coreutils}/bin/echo "    DATA           JSON data to encrypt"
    ${pkgs.coreutils}/bin/echo "    DESTINATION    Outputh path of the encrypted file"
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

  ensure_json() {
    if ! ${pkgs.jq}/bin/jq '.' <(echo "$DATA") >/dev/null; then
      die "data is not valid JSON"
    fi
  }

  encrypt_secret() {
    ${pkgs.jq}/bin/jq -jr '.' <(echo "$DATA") | ${pkgs.openssl}/bin/openssl enc -aes-256-cbc -md md5 -e -k "$(${pkgs.jq}/bin/jq -r '.appId' $GK_CONFIG)" -nosalt -out "$DESTINATION" 2>/dev/null
  }

  main() {
    ensure_config
    ensure_json
    encrypt_secret
  }

  DATA="''${1:-}"
  DESTINATION="''${2:-}"

  if test -z "$DATA"; then
    error "$SCRIPT_NAME requires data to encrypt"
    usage
  fi

  if test -z "$DESTINATION"; then
    error "$SCRIPT_NAME requires an output path"
    usage
  fi

  main
''

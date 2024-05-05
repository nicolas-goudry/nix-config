{ pkgs }:

let
  encrypt = import ./encrypt.nix { inherit pkgs; };
in
pkgs.writeScriptBin "gk-login" ''
  #!${pkgs.bash}/bin/bash

  set -euo pipefail

  # Variables
  SCRIPT_NAME="$(basename "$0")"

  # Helper constants
  GK_CONFIG_DIR=$HOME/.gitkraken
  BASE_URL="https://api.gitkraken.com/oauth"
  LOGIN_PATH="login?action=authorize&in_app=true"

  # Color codes
  NC="\e[0m"
  BOLD="\e[1m"
  DIM="\e[2m"
  YELLOW="\e[0;33m"
  BOLDYELLOW="\e[1;33m"
  RED="\e[0;31m"
  BOLDRED="\e[1;31m"
  BOLDGREEN="\e[1;32m"

  # Utility function to output error message
  error() {
    >&2 ${pkgs.coreutils}/bin/echo -e "''${BOLDRED}ERROR:$NC $RED$*$NC"
  }

  # Utility function to output warning message
  warn() {
    >&2 ${pkgs.coreutils}/bin/echo -e "''${BOLDYELLOW}WARN:$NC $YELLOW$*$NC"
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
    ${pkgs.coreutils}/bin/echo "Login to your GitKraken account from the command line."
    ${pkgs.coreutils}/bin/echo
    ${pkgs.coreutils}/bin/echo -e "''${BOLD}Usage:$NC"
    ${pkgs.coreutils}/bin/echo
    ${pkgs.coreutils}/bin/echo -e "    $DIM\$$NC $SCRIPT_NAME [options...]"
    ${pkgs.coreutils}/bin/echo
    ${pkgs.coreutils}/bin/echo -e "''${BOLD}Options:$NC"
    ${pkgs.coreutils}/bin/echo
    ${pkgs.coreutils}/bin/echo "    -P, --profile     Profile ID to use (defaults to default profile)"
    ${pkgs.coreutils}/bin/echo "    -p, --provider    Provider to login with"
    ${pkgs.coreutils}/bin/echo "    -h, --help        Show this help message"
    ${pkgs.coreutils}/bin/echo
    ${pkgs.coreutils}/bin/echo -e "''$BOLD}Available providers:$NC"
    ${pkgs.coreutils}/bin/echo
    ${pkgs.coreutils}/bin/echo "    github       : GitHub"
    ${pkgs.coreutils}/bin/echo "    gitlab       : GitLab"
    ${pkgs.coreutils}/bin/echo "    bitbucket    : Bitbucket"
    ${pkgs.coreutils}/bin/echo "    azure        : Azure DevOps"
    ${pkgs.coreutils}/bin/echo

    if test -z "''${1:-}"; then
      exit 0
    fi
  }

  ensure_provider() {
    if test -z "$PROVIDER"; then
      error "$SCRIPT_NAME requires a provider"
      usage
    fi

    if test "$PROVIDER" != "github" && test "$PROVIDER" != "gitlab" && test "$PROVIDER" != "bitbucket" && test "$PROVIDER" != "azure"; then
      error "provider '$PROVIDER' is invalid"
      usage
    fi
  }

  ensure_profile() {
    if test -z "$PROFILE"; then
      warn "no profile ID set, using default profile ID"
      PROFILE="d6e5a8ca26e14325a4275fc33b17e16f"
    fi
  }

  ensure_config() {
    if ! test -r "$GK_CONFIG_DIR/config"; then
      die "config file not found. Is GitKraken installed?"
    fi

    PROFILE_DIR="$GK_CONFIG_DIR/profiles/$PROFILE/$PROVIDER"
    ${pkgs.coreutils}/bin/mkdir -p "$PROFILE_DIR"
  }

  open_browser() {
    url=$BASE_URL/$PROVIDER/$LOGIN_PATH

    ${pkgs.coreutils}/bin/echo -e "''${BOLD}Opening a web browser to login to GitKraken account...$NC"
    ${pkgs.coreutils}/bin/echo -e "''${DIM}If this doesn't work, go to this URL in your browser: $url$NC"
    ${pkgs.xdg-utils}/bin/xdg-open $url &>/dev/null || true
  }

  set_token() {
    token=""

    while true; do
      read -rsp "Enter access token: " token
      ${pkgs.coreutils}/bin/echo

      if test -z "$token"; then
        error "access token is empty"
      elif ! ${pkgs.coreutils}/bin/base64 -d <(echo "$token") >/dev/null; then
        error "invalid access token provided, expected a base64 encoded string"
      else
        break
      fi
    done

    OAUTH_TOKEN=$token
  }

  extract_token() {
    if test -z "$OAUTH_TOKEN"; then
      die "missing access token"
    fi

    expandedToken=$(${pkgs.coreutils}/bin/base64 -d <(echo "$OAUTH_TOKEN") | ${pkgs.pigz}/bin/pigz -d)

    if test -z "$expandedToken"; then
      die "failed to expand access token"
    fi

    PROVIDER_TOKEN=$(${pkgs.jq}/bin/jq -r '.access_token' <(echo "$expandedToken"))

    if test -z "$PROVIDER_TOKEN"; then
      die "failed to retrieve provider token"
    fi
  }

  encrypt_token() {
    ${encrypt}/bin/gk-encrypt "{ \"GitKraken\": { \"accessToken\": \"$PROVIDER_TOKEN\" } }" "$PROFILE_DIR/secFile"
  }

  main() {
    ensure_provider
    ensure_profile
    ensure_config
    open_browser
    set_token
    extract_token
    encrypt_token

    ${pkgs.coreutils}/bin/echo -e "''${BOLDGREEN}GitKraken authentication successful!$NC"
    ${pkgs.coreutils}/bin/echo
    ${pkgs.coreutils}/bin/echo "Restart or start GitKraken for changes to take effect."
  }

  PROFILE=""
  PROFILE_DIR=""
  PROVIDER=""
  OAUTH_TOKEN=""
  PROVIDER_TOKEN=""

  # Read script flags
  while getopts 'hP:p:-:' OPT; do
    # support long options: https://stackoverflow.com/a/28466267/519360
    if test "$OPT" = "-"; then # long option: reformulate OPT and OPTARG
      OPT="''${OPTARG%%=*}" # extract long option name
      # shellcheck disable=SC2295
      OPTARG="''${OPTARG#$OPT}" # extract long option argument (may be empty)
      OPTARG="''${OPTARG#=}" # if long option argument, remove assigning `=`
    fi

    # Handle flags
    case "$OPT" in
      p | provider )
        PROVIDER="$OPTARG"
        ;;
      P | profile )
        PROFILE="$OPTARG"
        ;;
      h | help )
        usage
        ;;
      ??* ) # bad long option
        error "illegal option --$OPT"
        usage noexit
        die
        ;;
      ? ) # bad short option (error reported via getopts)
        usage noexit
        die
        ;;
    esac
  done

  main
''

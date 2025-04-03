#!/usr/bin/env bash

# set +e # Do not exit on error
set -e # Exit on error
set +u # Allow unset variables
# set -u # Exit on unset variable
# set +o pipefail # Disable pipefail
set -o pipefail # Enable pipefail

script_name=$(basename "${0}")
nc="\e[0m" # Unset styles
bld="\e[1m" # Bold text
dim="\e[2m" # Dim text
red="\e[31m" # Red foreground
green="\e[32m" # Green foreground
yellow="\e[33m" # Yellow foreground
blue="\e[34m" # Blue foreground

to_stderr() {
  >&2 echo -e "${*}"
}

to_stdout() {
  echo -e "${*}"
}

error() {
  to_stderr " ${red}×${nc} ${*}"
}

warn() {
  to_stderr " ${yellow}⚠${nc} ${*}"
}

info() {
  to_stdout " ${blue}i${nc} ${*}"
}

debug() {
  if [ -n "${debug}" ]; then
    to_stderr " ${dim}▶ ${*}${nc}"
  fi
}

success() {
  to_stdout " ${green}✓${nc} ${*}"
}

trace() {
  to_stderr "Stacktrace:"

  local i=1 line file func
  while read -r line func file < <(caller ${i}); do
    to_stderr "[${i}] ${file}:${line} ${func}(): $(sed -n "${line}p" "${file}")"
    ((i++))
  done
}

# shellcheck disable=SC2120
die() {
  if [ "${#}" -gt 0 ]; then
    error "${*}"
  fi

  exit 1
}

needs_arg() {
  if [ -z "${OPTARG}" ]; then
    >&2 echo "${0}: option requires an argument -- ${OPT}"
    usage
    die
  fi
}

usage() {
  echo
  echo "Template script."
  echo
  to_stdout "${bld}Usage:${nc}"
  to_stdout "    ${dim}\$${nc} ${script_name}"
  echo
  to_stdout "${bld}Options:${nc}"
  cat <<EOF | column -tds '|'
    -e, --error|Exit with error
    -o, --option|Some option
    -d, --debug|Enable debug output
    -h, --help|Show this help message
EOF
}

main() {
  while getopts 'hdeo:-:' OPT; do
    # support long options: https://stackoverflow.com/a/28466267/519360
    if test "$OPT" = "-"; then # long option: reformulate OPT and OPTARG
      OPT="${OPTARG%%=*}" # extract long option name
      # shellcheck disable=SC2295
      OPTARG="${OPTARG#$OPT}" # extract long option argument (may be empty)
      OPTARG="${OPTARG#=}" # if long option argument, remove assigning `=`
    fi

    # Handle flags
    case "$OPT" in
      e | error )
        die "exited with error"
        ;;
      o | option )
        needs_arg
        OPTION="${OPTARG}"
        ;;
      d | debug )
        debug=true
        ;;
      h | help )
        usage
        exit 0
        ;;
      ??* ) # bad long option
        >&2 echo "${0}: illegal option -- $OPT"
        usage
        die
        ;;
      ? ) # bad short option (error reported via getopts)
        usage
        die
        ;;
    esac
  done

  debug "Start of main"
  echo "This is a template."

  if [ -n "${OPTION}" ]; then
    debug "Option is not empty"
    echo "Option is set to: ${OPTION}"
  fi
}

main "$@"

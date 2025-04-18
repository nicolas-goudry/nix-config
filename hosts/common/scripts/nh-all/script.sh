#!/usr/bin/env bash

set +u -eo pipefail

script_name=$(basename "${0}")
nc="\e[0m" # Unset styles
bld="\e[1m" # Bold text
dim="\e[2m" # Dim text
red="\e[31m" # Red foreground
green="\e[32m" # Green foreground
yellow="\e[33m" # Yellow foreground
blue="\e[34m" # Blue foreground

action="build"

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
  to_stdout
  to_stdout "Build or switch NixOS and Home Manager configurations using 'nh'."
  to_stdout
  to_stdout "${bld}Usage:${nc}"
  to_stdout "    ${dim}\$${nc} ${script_name} <build|switch> [options]"
  to_stdout
  to_stdout "${bld}Options:${nc}"
  cat <<EOF | column -tds '|'
    -h, --help|Show this help message
EOF
}

main() {
  while getopts 'h-:' OPT; do
    # support long options: https://stackoverflow.com/a/28466267/519360
    if test "$OPT" = "-"; then # long option: reformulate OPT and OPTARG
      OPT="${OPTARG%%=*}" # extract long option name
      # shellcheck disable=SC2295
      OPTARG="${OPTARG#$OPT}" # extract long option argument (may be empty)
      OPTARG="${OPTARG#=}" # if long option argument, remove assigning `=`
    fi

    # Handle flags
    case "$OPT" in
      h | help )
        usage
        exit 0
        ;;
    esac
  done

  if ! [[ "${1}" =~ ^(build|switch)$ ]]; then
    error "Invalid action provided: ${1}"
    usage
    die
  else
    action="${1}"
    shift
  fi

  for builder in nh-home nh-host; do
    if command -v "${builder}" &> /dev/null; then
      "${builder}" "${action}"
    else
      warn "${builder} not found"
    fi
  done
}

main "$@"

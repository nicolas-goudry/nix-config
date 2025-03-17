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

nixstrap="${HOME}/nixstrap"
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
  echo "Build or switch Home Manager configuration using 'nh'."
  echo
  to_stdout "${bld}Usage:${nc}"
  to_stdout "    ${dim}\$${nc} ${script_name} <build|switch>"
  echo
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

  if [ -z "${1}" ]; then
    warn "No argument specified, assuming ${action}"
  elif ! [[ "${1}" =~ ^(build|switch)$ ]]; then
    error "Invalid argument: ${1}"
    usage
    die
  else
    action="${1}"
  fi

  if ! [ -d "${nixstrap}" ]; then
    die "Bootstrap configuration not found in ${nixstrap}"
  fi

  if [ "$(uname -s)" == "Darwin" ]; then
    all_cores=$(sysctl -n hw.logicalcpu)
  else
    all_cores=$(nproc)
  fi

  build_cores=$(LC_NUMERIC="en_US.UTF-8" printf "%.0f" "$(echo "${all_cores} * 0.75" | bc)")
  info "${action^}ing Home Manager  with ${build_cores} cores"
  extra_args=()

  if [ "${action}" == "switch" ]; then
    extra_args=("--backup-extension" "$(date +%y%m%d_%H%M%S)")
  fi

  nh home "${action}" "${extra_args[@]}" "${nixstrap}" -- --cores "${build_cores}"
}

main "$@"

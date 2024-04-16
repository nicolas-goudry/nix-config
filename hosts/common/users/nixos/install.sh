#!/usr/bin/env bash

set -euo pipefail

# Variables
SCRIPT_NAME="$(basename "$0")"
TARGET_HOST="${1:-}"
TARGET_USER="${2:-}"
TARGET_BRANCH="${3:-main}"

# Helper constants
SOURCE_REPO="https://github.com/nicolas-goudry/nix-config.git"
SOURCE_REPO_SSH="git@github.com:nicolas-goudry/nix-config.git"
FLAKE_NAME="nixstrap"
LOCAL_CLONE_DIR="${HOME}/${FLAKE_NAME}"
FLAKE_DESTINATION="home/${TARGET_USER}/${FLAKE_NAME}"

# Color codes
NC="\e[0m"
BOLD="\e[1m"
DIM="\e[2m"
YELLOW="\e[33m"
RED="\e[31m"

# Utility function to output error message
error() {
  >&2 echo -e "${RED}${BOLD}ERROR:${NC}${RED} $*${NC}"
}

# Utility function to output warning message
warn() {
  >&2 echo -e "${YELLOW}${BOLD}WARN:${NC}${YELLOW} $*${NC}"
}

# Utility function to exit script with optional error message
die() {
  if test "$#" -gt 0; then
    error "$*"
  fi

  exit 1
}

# Help usage (accepts an argument to prevent script exit right way)
usage() {
  echo
  echo "NixOS installation helper script."
  echo
  echo -e "${BOLD}Usage:${NC}"
  echo
  echo -e "    ${DIM}\$${NC} $SCRIPT_NAME HOSTNAME USERNAME [BRANCH] [options]"
  echo
  echo -e "${BOLD}Arguments:${NC}"
  echo
  echo "    HOSTNAME    Hostname to install NixOS to"
  echo "    USERNAME    Username to install NixOS with"
  echo "    BRANCH      Branch to use for configurations ${DIM}(default: ${BOLD}main${NC}${DIM})${NC}"
  echo
  echo -e "${BOLD}Options:${NC}"
  echo
  echo "    -h, --help       Show this help message"
  echo

  if test -z "${1:-}"; then
    exit 0
  fi
}

# Make sure script is not run as root
ensure_nonroot() {
  if test "$(id -u)" -eq 0; then
    die "${SCRIPT_NAME} should be run as a regular user"
  fi
}

# Make sure repository is available and setup
ensure_repo() {
  # Clone source repository if not available
  if ! test -d "${LOCAL_CLONE_DIR}/.git"; then
    git clone "${SOURCE_REPO}" "${LOCAL_CLONE_DIR}"
  fi

  # Switch to branch if requested
  if test -n "${TARGET_BRANCH}"; then
    pushd "${LOCAL_CLONE_DIR}"
    git checkout "${TARGET_BRANCH}"
    popd
  fi
}

# Make sure host is defined and valid
ensure_host() {
  local hosts
  local is_error=true

  # Gather valid hosts
  hosts=$(find "${LOCAL_CLONE_DIR}/hosts" -mindepth 2 -maxdepth 2 -type f -name 'default.nix' -exec dirname {} \; | cut -d'/' -f6 | grep -v iso)

  if test -z "${TARGET_HOST}"; then
    error "${SCRIPT_NAME} requires a hostname as the first argument"
  elif ! echo "${hosts}" | grep -w -q "${TARGET_HOST}"; then
    error "invalid hostname provided: ${TARGET_HOST}"
  else
    is_error=false
  fi

  # In case of error, output available hosts
  if test "${is_error}" = "true"; then
    echo
    echo "The following hosts are available:"

    for host in ${hosts}; do
      echo "- ${host}"
    done

    die
  fi
}

# Make sure user is defined and valid
ensure_user() {
  local users
  local is_error=true

  # Gather valid users
  users=$(find "${LOCAL_CLONE_DIR}/hosts/common/users" -mindepth 2 -type f -name 'default.nix' -exec dirname {} \; | cut -d'/' -f8 | grep -vE 'nixos|root')

  if test -z "${TARGET_USER}"; then
    error "${SCRIPT_NAME} requires a username as the second argument"
  elif ! echo "${users}" | grep -w -q "${TARGET_USER}"; then
    error "invalid hostname provided: ${TARGET_USER}"
  else
    is_error=false
  fi

  # In case of error, output available users
  if test "${is_error}" = "true"; then
    echo
    echo "The following users are available:"

    for user in ${users}; do
      echo "- ${user}"
    done

    die
  fi
}

# Make sure a valid PGP key is available to decrypt secrets
ensure_pgp_key() {
  local has_key=false
  local known_keys
  local avail_keys

  # Gather known keys from .sops.yaml file
  known_keys=$(yq '.keys | [.. | arrays] | flatten | map(ascii_upcase)' "${LOCAL_CLONE_DIR}/.sops.yaml" | jq -r '.[] | @text')

  # Gather available keys from host
  avail_keys=$(gpg --list-secret-keys --with-colons | awk -F: '$1 == "fpr" { print $10 }')

  # Search for any known key is available keys
  for known_key in ${known_keys}; do
    for avail_key in ${avail_keys}; do
      if test "${known_key}" = "${avail_key}"; then
        has_key=true
        break
      fi
    done
  done

  # If no key was found, error out with hint message
  if test "${has_key}" = false; then
    error "no known PGP key was found"
    echo
    echo -e "Import a known key with: ${BOLD}gpg --import <path-to-key>${NC}"
    die
  fi
}

# Make sure disk configuration file or disk preparation script is present
ensure_disks_config() {
  if test -x "${LOCAL_CLONE_DIR}/hosts/${TARGET_HOST}/disks.sh"; then
    true # Do nothing since disk preparation script was found
  elif ! test -e "${LOCAL_CLONE_DIR}/hosts/${TARGET_HOST}/disks.nix"; then
    die "could not find disko disks configuration file nor disk preparation script"
  fi
}

# Check if the host we're provisioning expects a password to unlock a disk
# If it does, prompt for it
configure_disk_encryption() {
  if grep -q "data.passwordFile" "${LOCAL_CLONE_DIR}/hosts/$TARGET_HOST/disks.nix"; then
    warn "disk configuration requires encryption!"
    echo

    while true; do
      read -rsp "Enter password  : " password
      read -rsp "Confirm password: " password_confirm

      if test "${password}" = "${password_confirm}"; then
        break
      else
        error "passwords do not match, please try again"
      fi
    done

    # Write the password with no trailing newline (important!)
    echo -n "${password}" > /tmp/data.passwordFile
  fi
}

# Run disko with given config and mode
run_disko() {
  local config="${1}"
  local mode="${2}"
  local REPLY

  # Make sure config file exists
  if test -e "${config}"; then
    return
  fi

  if test "${mode}" != "mount"; then
    warn "host disks will be formatted.\n\
      This is a destructive operation!"
    echo
    read -r -p "Continue? [y/N]" -n 1
  else
    REPLY="y"
  fi

  case $REPLY in
    [yY] )
      sudo true
      # Workaround for mounting encrypted bcachefs filesystems
      # - https://nixos.wiki/wiki/Bcachefs#NixOS_installation_on_bcachefs
      # - https://github.com/NixOS/nixpkgs/issues/32279
      sudo keyctl link @u @s
      sudo disko --mode "${mode}" "${config}"
      ;;
    * )
      echo -e "${BOLD}Operation aborted.${NC}"
      exit 0
      ;;
  esac
}

# Prepare host disks
prepare_disks() {
  # Run disk preparation script if it exists, else run disko
  if test -x "${LOCAL_CLONE_DIR}/hosts/${TARGET_HOST}/disks.sh"; then
    # Fail if disk preparation script failed
    if ! sudo "${LOCAL_CLONE_DIR}/hosts/${TARGET_HOST}/disks.sh" "$TARGET_USER"; then
      die "failed to prepare disks"
    fi
  else
    # Configure disk encryption (if required) before running disko
    configure_disk_encryption
    run_disko "${LOCAL_CLONE_DIR}/hosts/${TARGET_HOST}/disks.nix" "disko"

    # If the main configuration was denied, make sure the root partition is mounted
    if ! mountpoint -q /mnt; then
      run_disko "${LOCAL_CLONE_DIR}/hosts/${TARGET_HOST}/disks.nix" "mount"
    fi

    # Prepare additional disks if required
    for additional_disk in $(find "${LOCAL_CLONE_DIR}/hosts/${TARGET_HOST}" -name "disks-*.nix" | sort); do
      run_disko "${additional_disk}" "disko"
      run_disko "${additional_disk}" "mount"
    done
  fi

  # Make sure disk preparation was successful
  if ! mountpoint -q /mnt; then
    die "/mnt is not mounted"
  fi
}

# Install NixOS in /mnt
install_nixos() {
  warn "NixOS will be installed (or re-installed).\n\
      This is a destructive operation!"
  echo
  read -r -p "Continue? [y/N] " -n 1

  case $REPLY in
    [yY] ) echo ;;
    * )
      echo -e "${BOLD}Operation aborted.${NC}"
      exit 0
      ;;
  esac

  # Install NixOS without prompting for root password
  pushd "${LOCAL_CLONE_DIR}"
  sudo nixos-install --no-root-password --flake ".#${TARGET_HOST}"
  popd

  # Rsync nix-config to the target install and set the remote origin to SSH for later use
  rsync -a --delete "${LOCAL_CLONE_DIR}" "/mnt/${FLAKE_DESTINATION}"
  pushd "/mnt/${FLAKE_DESTINATION}"
  git remote set-url origin "${SOURCE_REPO_SSH}"
  popd
}

# Apply home-manager configuration for target user in /mnt
setup_home_manager() {
  sudo nixos-enter --root /mnt --command "chown -R ${TARGET_USER}:users /home/${TARGET_USER}"
  sudo nixos-enter --root /mnt --command "cd /${FLAKE_DESTINATION}; env USER=${TARGET_USER} HOME=/home/${TARGET_USER} home-manager switch --flake \".#${TARGET_USER}@${TARGET_HOST}\""
  sudo nixos-enter --root /mnt --command "chown -R ${TARGET_USER}:users /home/${TARGET_USER}"
}

main() {
  ensure_nonroot
  ensure_repo
  ensure_host
  ensure_user
  ensure_pgp_key
  ensure_disks_config
  prepare_disks
  install_nixos
  setup_home_manager
}

# Read script flags
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
      ;;
    ??* ) # bad long option
      error "illegal option --${OPT}"
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

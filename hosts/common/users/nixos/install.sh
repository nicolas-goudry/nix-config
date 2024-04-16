#!/usr/bin/env bash

set -euo pipefail

# Variables
SCRIPT_NAME="$(basename "$0")"

# Helper constants
SOURCE_REPO="https://github.com/nicolas-goudry/nix-config.git"
SOURCE_REPO_SSH="git@github.com:nicolas-goudry/nix-config.git"
FLAKE_NAME="nixstrap"
LOCAL_CLONE_DIR="${HOME}/${FLAKE_NAME}"

# Color codes
NC="\e[0m"
BOLD="\e[1m"
DIM="\e[2m"
YELLOW="\e[0;33m"
BOLDYELLOW="\e[1;33m"
RED="\e[0;31m"
BOLDRED="\e[1;31m"
GREEN="\e[0;32m"
BOLDGREEN="\e[1;32m"

# Utility function to output error message
error() {
  >&2 echo -e "${BOLDRED}ERROR:${NC} ${RED}$*${NC}"
}

# Utility function to output warning message
warn() {
  >&2 echo -e "${BOLDYELLOW}WARN:${NC} ${YELLOW}$*${NC}"
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
  echo
  echo "NixOS installation helper script."
  echo
  echo -e "${BOLD}Usage:${NC}"
  echo
  echo -e "    ${DIM}\$${NC} $SCRIPT_NAME [options...]"
  echo
  echo -e "${BOLD}Options:${NC}"
  echo
  echo "    -H, --host      Host to install NixOS to"
  echo "    -u, --user      Username to install NixOS with"
  echo "    -b, --branch    Branch to use for configurations ${DIM}(default: main)${NC}"
  echo "    -K, --gpg       GnuPG key to use"
  echo "    -h, --help      Show this help message"
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
    echo -e "${BOLD}Retrieving source repository from git...${NC}"
    echo -e "${DIM}Source: ${SOURCE_REPO}${NC}"
    echo -e "${DIM}Branch: ${TARGET_BRANCH}${NC}"
    git clone --quiet "${SOURCE_REPO}" "${LOCAL_CLONE_DIR}"
  fi

  echo -e "${GREEN}Source repository is available on system at ${NC}${BOLDGREEN}${LOCAL_CLONE_DIR}${NC}${GREEN}.${NC}"

  # Switch to branch
  pushd "${LOCAL_CLONE_DIR}" > /dev/null
  git checkout --quiet "${TARGET_BRANCH}"
  popd > /dev/null
}

# Make sure host is defined and valid
ensure_host() {
  local hosts
  local is_error=true

  # Gather valid hosts
  hosts=$(find "${LOCAL_CLONE_DIR}/hosts" -mindepth 2 -maxdepth 2 -type f -name 'default.nix' -exec dirname {} \; | cut -d'/' -f6 | grep -v iso)

  if test -z "${TARGET_HOST}"; then
    echo
    error "${SCRIPT_NAME} requires a hostname"
  elif ! echo "${hosts}" | grep -x -q "${TARGET_HOST}"; then
    echo
    error "invalid hostname provided: ${TARGET_HOST}"
  else
    is_error=false
  fi

  # In case of error, output available hosts
  if test "${is_error}" = "true"; then
    usage noexit
    echo "Hosts:"
    echo

    for host in ${hosts}; do
      echo "    ${host}"
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
    echo
    error "${SCRIPT_NAME} requires a username"
  elif ! echo "${users}" | grep -w -q "${TARGET_USER}"; then
    echo
    error "invalid username provided: ${TARGET_USER}"
  else
    is_error=false
  fi

  # In case of error, output available users
  if test "${is_error}" = "true"; then
    usage noexit
    echo "Users:"
    echo

    for user in ${users}; do
      echo "    ${user}"
    done

    die
  fi
}

# Make sure a valid gpg key was provided to decrypt secrets
ensure_gpg_key() {
  local known_keys

  if ! test -e "${HOME}/.gnupg/trustdb.gpg"; then
    die "gpg trust database was not found\n\
       Did you import your keypair?"
  elif test -z "${GPG_KEY}"; then
    echo
    error "${SCRIPT_NAME} requires a gpg key"
    usage
  elif ! gpg -K "${GPG_KEY}" &> /dev/null; then
    echo
    die "provided gpg key was not found in keyring\n\
       Make sure to import the secret key!"
  fi

  # Gather known keys from .sops.yaml file
  known_keys=$(yq '.keys | [.. | arrays] | flatten | map(ascii_upcase)' "${LOCAL_CLONE_DIR}/.sops.yaml" | jq -r '.[] | @text')

  # Fail if key is not known by sops
  if ! echo "${known_keys}" | grep -x -q "${GPG_KEY}"; then
    echo
    die "provided gpg key is not a known installation key"
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
    echo
    warn "disk configuration requires encryption!"

    while true; do
      read -rsp "Enter password  : " password
      echo
      read -rsp "Confirm password: " password_confirm
      echo

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
  if ! test -e "${config}"; then
    return
  fi

  if test "${mode}" != "mount"; then
    echo
    warn "host disks will be formatted.\n\
      This is a destructive operation!"
    echo
    read -r -p "Continue? [y/N] " -n 1
    echo
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
  echo
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
  rsync -a --delete "${LOCAL_CLONE_DIR}" "/mnt/home/${TARGET_USER}/"
  pushd "/mnt/home/${TARGET_USER}/${FLAKE_NAME}"
  git remote set-url origin "${SOURCE_REPO_SSH}"
  popd

  # Add host key to sops known keys and update secrets keys
  local host_gpg_key
  local flake_destination="/mnt/home/${TARGET_USER}/${FLAKE_NAME}"

  host_gpg_key=$(ssh-to-pgp -i /mnt/etc/ssh/ssh_host_rsa_key -o /dev/null)

  sed -i.backup "/&${TARGET_HOST}/d" "${flake_destination}/.sops.yaml"
  sed -i "/*${TARGET_HOST}/d" "${flake_destination}/.sops.yaml"
  sed -i "/  hosts:/a\ \ \ \ - &${TARGET_HOST} ${host_gpg_key}" "${flake_destination}/.sops.yaml"
  sed -i "/pgp:/a\ \ \ \ \ \ \ \ \ \ - *${TARGET_HOST}" "${flake_destination}/.sops.yaml"
  find "${flake_destination}" -type f -name 'secrets.y*ml' -exec sops updatekeys {} \;
}

# Apply home-manager configuration for target user in /mnt if it exists
setup_home_manager() {
  if test -d "${LOCAL_CLONE_DIR}/users/${TARGET_USER}"; then
    sudo nixos-enter --root /mnt --command "chown -R ${TARGET_USER}:users /home/${TARGET_USER}"
    sudo nixos-enter --root /mnt --command "cd /home/${TARGET_USER}/${FLAKE_NAME}; env USER=${TARGET_USER} HOME=/home/${TARGET_USER} home-manager switch --flake \".#${TARGET_USER}@${TARGET_HOST}\""
    sudo nixos-enter --root /mnt --command "chown -R ${TARGET_USER}:users /home/${TARGET_USER}"
  fi
}

main() {
  ensure_nonroot
  ensure_repo
  ensure_host
  ensure_user
  ensure_gpg_key
  ensure_disks_config
  prepare_disks
  install_nixos
  setup_home_manager

  echo -e "${GREEN}Installation successful!${NC}"
  echo
  echo "After reboot, ensure to commit and push repository changes to git."
}

TARGET_HOST=""
TARGET_USER=""
GPG_KEY=""
TARGET_BRANCH="main"

# Read script flags
while getopts 'hH:u:b:K:-:' OPT; do
  # support long options: https://stackoverflow.com/a/28466267/519360
  if test "$OPT" = "-"; then # long option: reformulate OPT and OPTARG
    OPT="${OPTARG%%=*}" # extract long option name
    # shellcheck disable=SC2295
    OPTARG="${OPTARG#$OPT}" # extract long option argument (may be empty)
    OPTARG="${OPTARG#=}" # if long option argument, remove assigning `=`
  fi

  # Handle flags
  case "$OPT" in
    H | host )
      TARGET_HOST="${OPTARG}"
      ;;
    u | user )
      TARGET_USER="${OPTARG}"
      ;;
    b | branch )
      TARGET_BRANCH="${OPTARG}"
      ;;
    K | gpg )
      GPG_KEY="${OPTARG}"
      ;;
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

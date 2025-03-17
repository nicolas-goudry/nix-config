#!/usr/bin/env bash

set -euo pipefail

script_name=$(basename "${0}")
nc="\e[0m" # Unset styles
bld="\e[1m" # Bold text
dim="\e[2m" # Dim text
red="\e[31m" # Red foreground
green="\e[32m" # Green foreground
yellow="\e[33m" # Yellow foreground
blue="\e[34m" # Blue foreground

source_repo="https://github.com/nicolas-goudry/nix-config.git"
source_repo_ssh="git@github.com:nicolas-goudry/nix-config.git"
flake_name="nixstrap"
clone_dir="${HOME}/${flake_name}"

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
    to_stderr "${0}: option requires an argument -- ${OPT}"
    usage
    die
  fi
}

usage() {
  to_stdout
  to_stdout "NixOS installation helper script."
  to_stdout
  to_stdout "${bld}Usage:${nc}"
  to_stdout "    ${dim}\$${nc} ${script_name}"
  to_stdout
  to_stdout "${bld}Options:${nc}"
  cat <<EOF | column -tds '|'
    -H, --host|Host to install NixOS to
    -u, --user|Username to install NixOS with
    -b, --branch|Branch to use for configuration|default: main
    -K, --gpg|GnuPG key to use
    --fetch-only|Clone source repository and exit
    -h, --help|Show this help message
EOF
}

# Make sure script is not run as root
ensure_nonroot() {
  if [ "$(id -u)" -eq 0 ]; then
    die "${script_name} must be run as a regular user"
  fi
}

# Make sure repository is available and setup
ensure_repo() {
  if [ "${1:-}" = "overwrite" ]; then
    rm -rf "${clone_dir}"
  fi

  # Clone source repository if not available
  if [ "${1:-}" = "overwrite" ] || ! [ -d "${clone_dir}/.git" ]; then
    to_stdout "${bld}Retrieving source repository from git...${nc}"
    to_stdout "${dim}Source: ${source_repo}${nc}"
    to_stdout "${dim}Branch: ${target_branch}${nc}"
    git clone --quiet "${source_repo}" "${clone_dir}"
  fi

  success "Source repository present"

  # Switch to branch
  git -C "${clone_dir}" checkout --quiet "${target_branch}"
}

# Make sure host is defined and valid
ensure_host() {
  local hosts
  local is_error=true

  # Gather valid hosts
  hosts=$(find "${clone_dir}/hosts" -mindepth 1 -maxdepth 1 -name common -prune -o -name 'iso-*' -prune -o -type d -printf '%f\n')

  if [ -z "${target_host}" ]; then
    error "Host is not defined"
  elif ! [[ "${target_host}" =~ ^($(echo "${hosts}" | tr '\n' '|'))$ ]]; then
    error "Invalid host provided: ${target_host}"
  else
    is_error=false
    success "Host set and valid"
  fi

  # In case of error, output available hosts
  if [ "${is_error}" = "true" ]; then
    to_stdout
    to_stdout "Available hosts:"

    for host in ${hosts}; do
      to_stdout "  - ${host}"
    done

    if [ -z "${target_host}" ]; then
      to_stdout
      to_stdout "Use '--host' to define the installation target host."
      to_stdout "See usage for details."
    fi

    die
  fi
}

# Make sure user is defined and valid
ensure_user() {
  local users
  local is_error=true

  # Gather valid users
  users=$(find "${clone_dir}/hosts/common/users" -mindepth 1 -maxdepth 1 -regextype egrep -regex '^.*(nixos|root)$' -prune -o -type d -printf '%f\n')

  if [ -z "${target_user}" ]; then
    error "User is not defined"
  elif ! [[ "${target_user}" =~ ^($(echo "${users}" | tr '\n' '|'))$ ]]; then
    error "Invalid user provided: ${target_user}"
  else
    is_error=false
    success "User set and valid"
  fi

  # In case of error, output available users
  if [ "${is_error}" = "true" ]; then
    to_stdout
    to_stdout "Available users:"

    for user in ${users}; do
      to_stdout "  - ${user}"
    done

    if [ -z "${target_user}" ]; then
      to_stdout
      to_stdout "Use '--user' to define the installation target user."
      to_stdout "See usage for details."
    fi

    die
  fi
}

# Make sure a valid gpg key was provided to decrypt secrets
ensure_gpg_key() {
  if [ -z "${gpg_key}" ]; then
    error "GPG key is not defined"
    usage
  elif ! gpg -K "${gpg_key}" &> /dev/null; then
    die "GPG key (${gpg_key}) was not found in keyring"
  else
    success "GPG key in keyring"
  fi

  # Gather known keys from .sops.yaml file
  local known_keys
  known_keys=$(yq '.keys.users | map(ascii_upcase)' "${clone_dir}/.sops.yaml" | jq -r '.[]')

  # Fail if key is not known by sops
  if ! echo "${known_keys}" | grep -x -q "${gpg_key}"; then
    die "GPG key is not a known installation key"
  fi

  # Import hosts public keys (needed for secrets re-encryption before install)
  for pubkey in "${clone_dir}"/.keys/*.pub; do
    gpg --import "${pubkey}";
  done
}

# Make sure disk configuration file or disk preparation script is present
ensure_disks_config() {
  if [ -x "${clone_dir}/hosts/${target_host}/disks.sh" ]; then
    true # Do nothing since disk preparation script was found
  elif ! [ -e "${clone_dir}/hosts/${target_host}/disks.nix" ]; then
    die "Disk configuration is missing: no disko configuration file nor disk preparation script was found for ${target_host}"
  fi
}
# Check if the host we're provisioning expects a password to unlock a disk
# If it does, prompt for it
configure_disk_encryption() {
  if grep -q "data.passwordFile" "${clone_dir}/hosts/${target_host}/disks.nix"; then
    warn "disk configuration requires encryption!"

    while true; do
      read -rsp "Enter password  : " password
      to_stdout
      read -rsp "Confirm password: " password_confirm
      to_stdout

      if test "${password}" = "${password_confirm}"; then
        break
      else
        error "Passwords do not match, please try again"
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
  local reply

  # Make sure config file exists
  if ! [ -e "${config}" ]; then
    return
  fi

  if [ "${mode}" != "mount" ]; then
    info "Host disks will be formatted"
    warn "This is a destructive operation"
    to_stdout
    read -r -p " ? Continue [y/N] " -n 1 reply
    to_stdout
  else
    reply="y"
  fi

  case ${reply} in
    [yY] ) ;;
    * )
      error "Operation aborted"
      exit 0
      ;;
  esac

  # Workaround for mounting encrypted bcachefs filesystems
  # - https://wiki.nixos.org/wiki/Bcachefs#NixOS_installation_on_bcachefs
  # - https://github.com/NixOS/nixpkgs/issues/32279
  sudo keyctl link @u @s
  sudo disko --mode "${mode}" "${config}"
}

# Prepare host disks
prepare_disks() {
  # Run disk preparation script if it exists, else run disko
  if [ -x "${clone_dir}/hosts/${target_host}/disks.sh" ]; then
    # Fail if disk preparation script failed
    if ! sudo "${clone_dir}/hosts/${target_host}/disks.sh" "${target_user}"; then
      die "failed to prepare disks"
    fi
  else
    # Configure disk encryption (if required) before running disko
    configure_disk_encryption
    run_disko "${clone_dir}/hosts/${target_host}/disks.nix" "disko"

    # If the main configuration was denied, make sure the root partition is mounted
    if ! mountpoint -q /mnt; then
      run_disko "${clone_dir}/hosts/${target_host}/disks.nix" "mount"
    fi

    # Prepare additional disks if required
    for additional_disk in $(find "${clone_dir}/hosts/${target_host}" -name "disks-*.nix" | sort); do
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
  local reply

  info "NixOS will be installed (or re-installed)"
  warn "This is a destructive operation"
  to_stdout
  read -r -p " ? Continue [y/N] " -n 1 reply
  to_stdout

  case ${reply} in
    [yY] ) ;;
    * )
      error "Operation aborted"
      exit 0
      ;;
  esac

  # Generate host SSH key
  # Usually this is handled by services.openssh.hostKeys when services.openssh.enable is true,
  # however the host SSH keys creation only happens before SSH daemon systemd service starts.
  # Since we cannot start systemd services through nix-enter, we have to manually generate the
  # host key after NixOS installation
  # See https://github.com/NixOS/nixpkgs/blob/nixos-23.11/nixos/modules/services/networking/ssh/sshd.nix#L555
  sudo ssh-keygen -q -t ed25519 -C "${target_host}" -f /tmp/ssh_host_ed25519_key -N ""

  # Derive host age public key from generated SSH key
  local host_age_key
  host_age_key=$(sudo ssh-to-age -i /tmp/ssh_host_ed25519_key.pub)

  # Add host to sops config
  local sops_config="${clone_dir}/.sops.yaml"
  sed -i.backup "/&${target_host}/d" "${sops_config}"
  sed -i "/*${target_host}/d" "${sops_config}"
  sed -i "/  hosts:/a\ \ \ \ - &${target_host} ${host_age_key}" "${sops_config}"
  sed -i "/age:/a\ \ \ \ \ \ \ \ \ \ - *${target_host}" "${sops_config}"

  # Update secrets for new host
  find "$(dirname "${sops_config}")" -type f -name 'secrets.y*ml' -exec sops --config "${sops_config}" updatekeys -y {} \;

  # Install NixOS without prompting for root password (handled via configuration)
  pushd "${clone_dir}" > /dev/null
  sudo nixos-install --no-root-password --flake ".#${target_host}"
  popd > /dev/null

  # Move generated SSH key pair to host filesystem
  sudo mv /tmp/ssh_host_ed25519_key* /mnt/etc/ssh

  # Rsync nix-config to the new host and set the remote origin to SSH for later use
  rsync -a --delete "${clone_dir}" "/mnt/home/${target_user}/"
  git -C "/mnt/home/${target_user}/${flake_name}" remote set-url origin "${source_repo_ssh}"

  # Enter to the new install and apply home-manager configuration
  sudo nixos-enter --root /mnt --command "chown -R ${target_user}:users /home/${target_user}"
  sudo nixos-enter --root /mnt --command "nix-daemon & env -C /home/${target_user}/${flake_name} su -c 'home-manager switch --flake \".#${target_user}@${target_host}\"' nicolas"
  sudo nixos-enter --root /mnt --command "chown -R ${target_user}:users /home/${target_user}"
}

main() {
  target_host=""
  target_user=""
  gpg_key=""
  target_branch="main"

  while getopts 'hH:u:b:K:-:' OPT; do
    # support long options: https://stackoverflow.com/a/28466267/519360
    if test "${OPT}" = "-"; then # long option: reformulate OPT and OPTARG
      OPT="${OPTARG%%=*}" # extract long option name
      # shellcheck disable=SC2295
      OPTARG="${OPTARG#${OPT}}" # extract long option argument (may be empty)
      OPTARG="${OPTARG#=}" # if long option argument, remove assigning `=`
    fi

    # Handle flags
    case "${OPT}" in
      H | host )
        needs_arg
        target_host="${OPTARG}"
        ;;
      u | user )
        needs_arg
        target_user="${OPTARG}"
        ;;
      b | branch )
        needs_arg
        target_branch="${OPTARG}"
        ;;
      K | gpg )
        needs_arg
        gpg_key="${OPTARG}"
        ;;
      "fetch-only" )
        ensure_repo overwrite
        exit 0
        ;;
      h | help )
        usage
        exit 0
        ;;
      ??* ) # bad long option
        to_stderr "${0}: illegal option -- ${OPT}"
        usage
        die
        ;;
      ? ) # bad short option (error reported via getopts)
        usage
        die
        ;;
    esac
  done

  ensure_nonroot
  ensure_repo
  ensure_host
  ensure_user
  ensure_gpg_key
  ensure_disks_config
  prepare_disks
  install_nixos

  success "Installation successful"
  info "After reboot, ensure to commit and push repository changes to git"
}

main "${@}"

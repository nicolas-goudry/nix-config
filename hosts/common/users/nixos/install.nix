{ disko, pkgs }:

''
  #!${pkgs.bash}/bin/bash

  set -euo pipefail

  # Variables
  SCRIPT_NAME="$(basename "$0")"

  # Helper constants
  SOURCE_REPO="https://github.com/nicolas-goudry/nix-config.git"
  SOURCE_REPO_SSH="git@github.com:nicolas-goudry/nix-config.git"
  FLAKE_NAME="nixstrap"
  LOCAL_CLONE_DIR="$HOME/$FLAKE_NAME"

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
    ${pkgs.coreutils}/bin/echo "NixOS installation helper script."
    ${pkgs.coreutils}/bin/echo
    ${pkgs.coreutils}/bin/echo -e "''${BOLD}Usage:$NC"
    ${pkgs.coreutils}/bin/echo
    ${pkgs.coreutils}/bin/echo -e "    $DIM\$$NC $SCRIPT_NAME [options...]"
    ${pkgs.coreutils}/bin/echo
    ${pkgs.coreutils}/bin/echo -e "''${BOLD}Options:$NC"
    ${pkgs.coreutils}/bin/echo
    ${pkgs.coreutils}/bin/echo "    -H, --host      Host to install NixOS to"
    ${pkgs.coreutils}/bin/echo "    -u, --user      Username to install NixOS with"
    ${pkgs.coreutils}/bin/echo -e "    -b, --branch    Branch to use for configurations $DIM(default: main)$NC"
    ${pkgs.coreutils}/bin/echo "    -K, --gpg       GnuPG key to use"
    ${pkgs.coreutils}/bin/echo "    --fetch-only    Clone source repository and exit"
    ${pkgs.coreutils}/bin/echo "    -h, --help      Show this help message"
    ${pkgs.coreutils}/bin/echo

    if test -z "''${1:-}"; then
      exit 0
    fi
  }

  # Make sure script is not run as root
  ensure_nonroot() {
    if test "$(id -u)" -eq 0; then
      die "$SCRIPT_NAME should be run as a regular user"
    fi
  }

  # Make sure repository is available and setup
  ensure_repo() {
    if test "''${1:-}" = "overwrite"; then
      ${pkgs.coreutils}/bin/rm -rf "$LOCAL_CLONE_DIR"
    fi

    # Clone source repository if not available
    if test "''${1:-}" = "overwrite" || ! test -d "$LOCAL_CLONE_DIR/.git"; then
      ${pkgs.coreutils}/bin/echo -e "''${BOLD}Retrieving source repository from git...$NC"
      ${pkgs.coreutils}/bin/echo -e "''${DIM}Source: $SOURCE_REPO$NC"
      ${pkgs.coreutils}/bin/echo -e "''${DIM}Branch: $TARGET_BRANCH$NC"
      ${pkgs.git}/bin/git clone --quiet "$SOURCE_REPO" "$LOCAL_CLONE_DIR"
    fi

    ${pkgs.coreutils}/bin/echo -e "''${GREEN}Source repository is available on system at $NC$BOLDGREEN$LOCAL_CLONE_DIR$NC$GREEN.$NC"

    # Switch to branch
    pushd "$LOCAL_CLONE_DIR" > /dev/null
    ${pkgs.git}/bin/git checkout --quiet "$TARGET_BRANCH"
    popd > /dev/null
  }

  # Make sure host is defined and valid
  ensure_host() {
    local hosts
    local is_error=true

    # Gather valid hosts
    hosts=$(${pkgs.findutils}/bin/find "$LOCAL_CLONE_DIR/hosts" -mindepth 2 -maxdepth 2 -type f -name 'default.nix' -exec ${pkgs.coreutils}/bin/dirname {} \; | ${pkgs.coreutils}/bin/cut -d'/' -f6 | ${pkgs.gnugrep}/bin/grep -v iso)

    if test -z "$TARGET_HOST"; then
      ${pkgs.coreutils}/bin/echo
      error "$SCRIPT_NAME requires a hostname"
    elif ! ${pkgs.coreutils}/bin/echo "$hosts" | ${pkgs.gnugrep}/bin/grep -x -q "$TARGET_HOST"; then
      ${pkgs.coreutils}/bin/echo
      error "invalid hostname provided: $TARGET_HOST"
    else
      is_error=false
    fi

    # In case of error, output available hosts
    if test "$is_error" = "true"; then
      usage noexit
      ${pkgs.coreutils}/bin/echo "Hosts:"
      ${pkgs.coreutils}/bin/echo

      for host in $hosts; do
        ${pkgs.coreutils}/bin/echo "    $host"
      done

      die
    fi
  }

  # Make sure user is defined and valid
  ensure_user() {
    local users
    local is_error=true

    # Gather valid users
    users=$(${pkgs.findutils}/bin/find "$LOCAL_CLONE_DIR/hosts/common/users" -mindepth 2 -type f -name 'default.nix' -exec ${pkgs.coreutils}/bin/dirname {} \; | ${pkgs.coreutils}/bin/cut -d'/' -f8 | ${pkgs.gnugrep}/bin/grep -vE 'nixos|root')

    if test -z "$TARGET_USER"; then
      ${pkgs.coreutils}/bin/echo
      error "$SCRIPT_NAME requires a username"
    elif ! ${pkgs.coreutils}/bin/echo "$users" | ${pkgs.gnugrep}/bin/grep -w -q "$TARGET_USER"; then
      ${pkgs.coreutils}/bin/echo
      error "invalid username provided: $TARGET_USER"
    else
      is_error=false
    fi

    # In case of error, output available users
    if test "$is_error" = "true"; then
      usage noexit
      ${pkgs.coreutils}/bin/echo "Users:"
      ${pkgs.coreutils}/bin/echo

      for user in $users; do
        ${pkgs.coreutils}/bin/echo "    $user"
      done

      die
    fi
  }

  # Make sure a valid gpg key was provided to decrypt secrets
  ensure_gpg_key() {
    if test -z "$GPG_KEY"; then
      ${pkgs.coreutils}/bin/echo
      error "$SCRIPT_NAME requires a gpg key"
      usage
    elif ! ${pkgs.gnupg}/bin/gpg -K "$GPG_KEY" &> /dev/null; then
      ${pkgs.coreutils}/bin/echo
      die "provided gpg key was not found in keyring\n\
         Make sure to import the secret key!"
    fi

    # Gather known keys from .sops.yaml file
    local known_keys
    known_keys=$(${pkgs.yq}/bin/yq '.keys.users | map(ascii_upcase)' "$LOCAL_CLONE_DIR/.sops.yaml" | ${pkgs.jq}/bin/jq -r '.[] | @text')

    # Fail if key is not known by sops
    if ! ${pkgs.coreutils}/bin/echo "$known_keys" | ${pkgs.gnugrep}/bin/grep -x -q "$GPG_KEY"; then
      ${pkgs.coreutils}/bin/echo
      die "provided gpg key is not a known installation key"
    fi

    # Import hosts public keys (needed for secrets re-encryption before install)
    for pubkey in $LOCAL_CLONE_DIR/.keys/*.pub; do
      ${pkgs.gnupg}/bin/gpg --import "$pubkey";
    done
  }

  # Make sure disk configuration file or disk preparation script is present
  ensure_disks_config() {
    if test -x "$LOCAL_CLONE_DIR/hosts/$TARGET_HOST/disks.sh"; then
      true # Do nothing since disk preparation script was found
    elif ! test -e "$LOCAL_CLONE_DIR/hosts/$TARGET_HOST/disks.nix"; then
      die "could not find disko disks configuration file nor disk preparation script"
    fi
  }

  # Check if the host we're provisioning expects a password to unlock a disk
  # If it does, prompt for it
  configure_disk_encryption() {
    if ${pkgs.gnugrep}/bin/grep -q "data.passwordFile" "$LOCAL_CLONE_DIR/hosts/$TARGET_HOST/disks.nix"; then
      ${pkgs.coreutils}/bin/echo
      warn "disk configuration requires encryption!"

      while true; do
        read -rsp "Enter password  : " password
        ${pkgs.coreutils}/bin/echo
        read -rsp "Confirm password: " password_confirm
        ${pkgs.coreutils}/bin/echo

        if test "$password" = "$password_confirm"; then
          break
        else
          error "passwords do not match, please try again"
        fi
      done

      # Write the password with no trailing newline (important!)
      ${pkgs.coreutils}/bin/echo -n "$password" > /tmp/data.passwordFile
    fi
  }

  # Run disko with given config and mode
  run_disko() {
    local config="$1"
    local mode="$2"
    local REPLY

    # Make sure config file exists
    if ! test -e "$config"; then
      return
    fi

    if test "$mode" != "mount"; then
      ${pkgs.coreutils}/bin/echo
      warn "host disks will be formatted.\n\
        This is a destructive operation!"
      ${pkgs.coreutils}/bin/echo
      read -r -p "Continue? [y/N] " -n 1
      ${pkgs.coreutils}/bin/echo
      ${pkgs.coreutils}/bin/echo
    else
      REPLY="y"
    fi

    case $REPLY in
      [yY] )
        sudo true
        # Workaround for mounting encrypted bcachefs filesystems
        # - https://wiki.nixos.org/wiki/Bcachefs#NixOS_installation_on_bcachefs
        # - https://github.com/NixOS/nixpkgs/issues/32279
        sudo ${pkgs.keyutils}/bin/keyctl link @u @s
        sudo ${disko}/bin/disko --mode "$mode" "$config"
        ;;
      * )
        ${pkgs.coreutils}/bin/echo -e "''${BOLD}Operation aborted.$NC"
        exit 0
        ;;
    esac
  }

  # Prepare host disks
  prepare_disks() {
    # Run disk preparation script if it exists, else run disko
    if test -x "$LOCAL_CLONE_DIR/hosts/$TARGET_HOST/disks.sh"; then
      # Fail if disk preparation script failed
      if ! sudo "$LOCAL_CLONE_DIR/hosts/$TARGET_HOST/disks.sh" "$TARGET_USER"; then
        die "failed to prepare disks"
      fi
    else
      # Configure disk encryption (if required) before running disko
      configure_disk_encryption
      run_disko "$LOCAL_CLONE_DIR/hosts/$TARGET_HOST/disks.nix" "disko"

      # If the main configuration was denied, make sure the root partition is mounted
      if ! ${pkgs.util-linux}/bin/mountpoint -q /mnt; then
        run_disko "$LOCAL_CLONE_DIR/hosts/$TARGET_HOST/disks.nix" "mount"
      fi

      # Prepare additional disks if required
      for additional_disk in $(${pkgs.findutils}/bin/find "$LOCAL_CLONE_DIR/hosts/$TARGET_HOST" -name "disks-*.nix" | ${pkgs.coreutils}/bin/sort); do
        run_disko "$additional_disk" "disko"
        run_disko "$additional_disk" "mount"
      done
    fi

    # Make sure disk preparation was successful
    if ! ${pkgs.util-linux}/bin/mountpoint -q /mnt; then
      die "/mnt is not mounted"
    fi
  }

  # Install NixOS in /mnt
  install_nixos() {
    ${pkgs.coreutils}/bin/echo
    warn "NixOS will be installed (or re-installed).\n\
        This is a destructive operation!"
    ${pkgs.coreutils}/bin/echo
    read -r -p "Continue? [y/N] " -n 1
    ${pkgs.coreutils}/bin/echo
    ${pkgs.coreutils}/bin/echo

    case $REPLY in
      [yY] ) ${pkgs.coreutils}/bin/echo ;;
      * )
        ${pkgs.coreutils}/bin/echo -e "''${BOLD}Operation aborted.$NC"
        exit 0
        ;;
    esac

    # Generate host SSH RSA key
    # Usually this is handled by services.openssh.hostKeys when services.openssh.enable is true,
    # however the host SSH keys creation only happens before SSH daemon systemd service starts.
    # Since we cannot start systemd services through nix-enter, we have to manually generate the
    # host key after NixOS installation
    # See https://github.com/NixOS/nixpkgs/blob/nixos-23.11/nixos/modules/services/networking/ssh/sshd.nix#L555
    sudo ${pkgs.openssh}/bin/ssh-keygen -q -t ed25519 -C "$TARGET_HOST" -f /tmp/ssh_host_ed25519_key -N ""

    # Derive host age public key from generated SSH RSA key
    local host_age_key
    host_age_key=$(sudo ${pkgs.ssh-to-age}/bin/ssh-to-age -i /tmp/ssh_host_ed25519_key.pub)

    # Add host to sops config
    local sops_config="$LOCAL_CLONE_DIR/.sops.yaml"
    ${pkgs.gnused}/bin/sed -i.backup "/&$TARGET_HOST/d" "$sops_config"
    ${pkgs.gnused}/bin/sed -i "/*$TARGET_HOST/d" "$sops_config"
    ${pkgs.gnused}/bin/sed -i "/  hosts:/a\ \ \ \ - &$TARGET_HOST $host_age_key" "$sops_config"
    ${pkgs.gnused}/bin/sed -i "/age:/a\ \ \ \ \ \ \ \ \ \ - *$TARGET_HOST" "$sops_config"

    # Update secrets for new host
    ${pkgs.findutils}/bin/find "$(dirname "$sops_config")" -type f -name 'secrets.y*ml' -exec ${pkgs.sops}/bin/sops --config "$sops_config" updatekeys -y {} \;

    # Install NixOS without prompting for root password (handled via configuration)
    pushd "$LOCAL_CLONE_DIR" > /dev/null
    sudo ${pkgs.nixos-install-tools}/bin/nixos-install --no-root-password --flake ".#$TARGET_HOST"
    popd > /dev/null

    # Move generated SSH RSA key to host filesystem
    sudo ${pkgs.coreutils}/bin/mv /tmp/ssh_host_ed25519_key /mnt/persist/etc/ssh

    # Rsync nix-config to the new host and set the remote origin to SSH for later use
    ${pkgs.rsync}/bin/rsync -a --delete "$LOCAL_CLONE_DIR" "/mnt/home/$TARGET_USER/"
    pushd "/mnt/home/$TARGET_USER/$FLAKE_NAME" > /dev/null
    ${pkgs.git}/bin/git remote set-url origin "$SOURCE_REPO_SSH"
    popd > /dev/null
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

    ${pkgs.coreutils}/bin/echo -e "''${GREEN}Installation successful!$NC"
    ${pkgs.coreutils}/bin/echo
    ${pkgs.coreutils}/bin/echo "After reboot, ensure to commit and push repository changes to git."
  }

  TARGET_HOST=""
  TARGET_USER=""
  GPG_KEY=""
  TARGET_BRANCH="main"

  # Read script flags
  while getopts 'hH:u:b:K:-:' OPT; do
    # support long options: https://stackoverflow.com/a/28466267/519360
    if test "$OPT" = "-"; then # long option: reformulate OPT and OPTARG
      OPT="''${OPTARG%%=*}" # extract long option name
      # shellcheck disable=SC2295
      OPTARG="''${OPTARG#$OPT}" # extract long option argument (may be empty)
      OPTARG="''${OPTARG#=}" # if long option argument, remove assigning `=`
    fi

    # Handle flags
    case "$OPT" in
      H | host )
        TARGET_HOST="$OPTARG"
        ;;
      u | user )
        TARGET_USER="$OPTARG"
        ;;
      b | branch )
        TARGET_BRANCH="$OPTARG"
        ;;
      K | gpg )
        GPG_KEY="$OPTARG"
        ;;
      "fetch-only" )
        ensure_repo overwrite
        exit 0
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

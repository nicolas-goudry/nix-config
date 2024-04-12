{ pkgs }:

pkgs.writeScriptBin "install-system" ''
  #!${pkgs.stdenv.shell}

  #set -euo pipefail

  TARGET_HOST="''${1:-}"
  TARGET_USER="''${2:-nicolas}"
  TARGET_BRANCH="''${3:-main}"

  function run_disko() {
    local DISKO_CONFIG="$1"
    local DISKO_MODE="$2"
    local REPLY="n"

    # If the requested config doesn't exist, skip it.
    if [ ! -e "$DISKO_CONFIG" ]; then
      return
    fi

    # If the requested mode is not mount, ask for confirmation.
    if [ "$DISKO_MODE" != "mount" ]; then
      ${pkgs.coreutils-full}/bin/echo "ALERT! Found $DISKO_CONFIG"
      ${pkgs.coreutils-full}/bin/echo "       Do you want to format the disks in $DISKO_CONFIG"
      ${pkgs.coreutils-full}/bin/echo "       This is a destructive operation!"
      ${pkgs.coreutils-full}/bin/echo
      read -p "Proceed with $DISKO_CONFIG format? [y/N]" -n 1 -r
      ${pkgs.coreutils-full}/bin/echo
    else
      REPLY="y"
    fi

    if [[ $REPLY =~ ^[Yy]$ ]]; then
      sudo true
      # Workaround for mounting encrypted bcachefs filesystems.
      # - https://nixos.wiki/wiki/Bcachefs#NixOS_installation_on_bcachefs
      # - https://github.com/NixOS/nixpkgs/issues/32279
      sudo ${pkgs.keyutils}/bin/keyctl link @u @s
      sudo disko --mode $DISKO_MODE "$DISKO_CONFIG"
    fi
  }

  if [ "$(${pkgs.coreutils-full}/bin/id -u)" -eq 0 ]; then
    ${pkgs.coreutils-full}/bin/echo "ERROR! $(${pkgs.coreutils}/bin/basename "$0") should be run as a regular user"
    exit 1
  fi

  if [ ! -d "$HOME/nixstrap/.git" ]; then
    ${pkgs.git}/bin/git clone https://github.com/nicolas-goudry/nix-config.git "$HOME/nixstrap"
  fi

  pushd "$HOME/nixstrap"

  if [[ -n "$TARGET_BRANCH" ]]; then
    ${pkgs.git}/bin/git checkout "$TARGET_BRANCH"
  fi

  if [[ -z "$TARGET_HOST" ]]; then
    ${pkgs.coreutils-full}/bin/echo "ERROR! $(basename "$0") requires a hostname as the first argument"
    ${pkgs.coreutils-full}/bin/echo "       The following hosts are available"
    ${pkgs.coreutils-full}/bin/ls -1 hosts/*/default.nix | ${pkgs.coreutils-full}/bin/cut -d'/' -f2 | ${pkgs.gnugrep}/bin/grep -v iso
    exit 1
  fi

  if [[ -z "$TARGET_USER" ]]; then
    ${pkgs.coreutils-full}/bin/echo "ERROR! $(basename "$0") requires a username as the second argument"
    ${pkgs.coreutils-full}/bin/echo "       The following users are available"
    ${pkgs.coreutils-full}/bin/ls -1 hosts/common/users/*/default.nix | ${pkgs.coreutils-full}/bin/cut -d'/' -f4 | ${pkgs.gnugrep}/bin/grep -v -E "nixos|root"
    exit 1
  fi

  if [ ! -e "$HOME/.config/sops/age/keys.txt" ]; then
    ${pkgs.coreutils-full}/bin/echo "WARNING! sops keys.txt was not found."
    ${pkgs.coreutils-full}/bin/echo "         Do you want to continue without it?"
    ${pkgs.coreutils-full}/bin/echo
    read -p "Are you sure? [y/N]" -n 1 -r
    ${pkgs.coreutils-full}/bin/echo
    if [[ $REPLY =~ ^[Nn]$ ]]; then
      IP=$(${pkgs.iproute2}/bin/ip route get 1.1.1.1 | ${pkgs.gawk}/bin/awk '{print $7}' | ${pkgs.coreutils-full}/bin/head -n 1)
      ${pkgs.coreutils-full}/bin/mkdir -p "$HOME/.config/sops/age"
      ${pkgs.coreutils-full}/bin/echo "From a trusted host run:"
      ${pkgs.coreutils-full}/bin/echo "scp ~/.config/sops/age/keys.txt $USER@$IP:.config/sops/age/keys.txt"
      exit
    fi
  fi

  if [ -x "hosts/$TARGET_HOST/disks.sh" ]; then
    if ! sudo hosts/$TARGET_HOST/disks.sh "$TARGET_USER"; then
      ${pkgs.coreutils-full}/bin/echo "ERROR! Failed to prepare disks; stopping here!"
      exit 1
    fi
  else
    if [ ! -e "hosts/$TARGET_HOST/disks.nix" ]; then
      ${pkgs.coreutils-full}/bin/echo "ERROR! $(basename "$0") could not find the required hosts/$TARGET_HOST/disks.nix"
      exit 1
    fi

    if ${pkgs.gnugrep}/bin/grep -q "data.passwordFile" "hosts/$TARGET_HOST/disks.nix"; then
      # If the machine we're provisioning expects a password to unlock a disk, prompt for it.
      while true; do
        # Prompt for the password, input is hidden
        read -rsp "Enter password:   " password
        echo
        # Prompt for the password again for confirmation
        read -rsp "Confirm password: " password_confirm
        echo
        # Check if both entered passwords match
        if [ "$password" == "$password_confirm" ]; then
          break
        else
          echo "Passwords do not match, please try again."
        fi
      done

      # Write the password to /tmp/data.passwordFile with no trailing newline
      ${pkgs.coreutils-full}/bin/echo -n "$password" > /tmp/data.passwordFile
    fi

    if ${pkgs.gnugrep}/bin/grep -q "data.keyFile" "hosts/$TARGET_HOST/disks.nix"; then
      # Check if the machine we're provisioning expects a keyfile to unlock a disk.
      # If it does, generate a new key, and write to a known location.
      ${pkgs.coreutils-full}/bin/echo -n "$(head -c32 /dev/random | base64)" > /tmp/data.keyFile
    fi

    run_disko "hosts/$TARGET_HOST/disks.nix" "disko"

    # If the main configuration was denied, make sure the root partition is mounted.
    if ! ${pkgs.util-linux}/bin/mountpoint -q /mnt; then
      run_disko "hosts/$TARGET_HOST/disks.nix" "mount"
    fi

    for CONFIG in $(${pkgs.findutils}/bin/find "hosts/$TARGET_HOST" -name "disks-*.nix" | ${pkgs.coreutils-full}/bin/sort); do
      run_disko "$CONFIG" "disko"
      run_disko "$CONFIG" "mount"
    done
  fi

  if ! ${pkgs.util-linux}/bin/mountpoint -q /mnt; then
    ${pkgs.coreutils-full}/bin/echo "ERROR! /mnt is not mounted; make sure the disk preparation was successful."
    exit 1
  fi

  ${pkgs.coreutils-full}/bin/echo "WARNING! NixOS will be re-installed"
  ${pkgs.coreutils-full}/bin/echo "         This is a destructive operation!"
  ${pkgs.coreutils-full}/bin/echo
  read -p "Are you sure? [y/N]" -n 1 -r
  ${pkgs.coreutils-full}/bin/echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Copy the sops keys.txt to the target install
    sudo nixos-install --no-root-password --flake ".#$TARGET_HOST"

    # Rsync nix-config to the target install and set the remote origin to SSH.
    ${pkgs.rsync}/bin/rsync -a --delete "$HOME/nixstrap/" "/mnt/home/$TARGET_USER/nixstrap/"
    if [ "$TARGET_HOST" != "minimech" ] && [ "$TARGET_HOST" != "scrubber" ]; then
      pushd "/mnt/home/$TARGET_USER/nixstrap"
      ${pkgs.git}/bin/git remote set-url origin git@github.com:nicolas-goudry/nix-config.git
      popd
    fi

    # Copy the sops keys.txt to the target install
    if [ -e "$HOME/.config/sops/age/keys.txt" ]; then
      ${pkgs.coreutils-full}/bin/mkdir -p /mnt/home/$TARGET_USER/.config/sops/age
      ${pkgs.coreutils-full}/bin/cp "$HOME/.config/sops/age/keys.txt" /mnt/home/$TARGET_USER/.config/sops/age/keys.txt
      ${pkgs.coreutils-full}/bin/chmod 600 /mnt/home/$TARGET_USER/.config/sops/age/keys.txt
    fi

    # Enter to the new install and apply the home-manager configuration.
    sudo nixos-enter --root /mnt --command "${pkgs.coreutils-full}/bin/chown -R $TARGET_USER:users /home/$TARGET_USER"
    sudo nixos-enter --root /mnt --command "cd /home/$TARGET_USER/nixstrap; env USER=$TARGET_USER HOME=/home/$TARGET_USER ${pkgs.home-manager}/bin/home-manager switch --flake \".#$TARGET_USER@$TARGET_HOST\""
    sudo nixos-enter --root /mnt --command "${pkgs.coreutils-full}/bin/chown -R $TARGET_USER:users /home/$TARGET_USER"

    # If there is a keyfile for a data disk, copy it to the root partition and
    # ensure the permissions are set appropriately.
    if [[ -f "/tmp/data.keyFile" ]]; then
      sudo ${pkgs.coreutils-full}/bin/cp /tmp/data.keyFile /mnt/etc/data.keyFile
      sudo ${pkgs.coreutils-full}/bin/chmod 0400 /mnt/etc/data.keyFile
    fi
  fi
''

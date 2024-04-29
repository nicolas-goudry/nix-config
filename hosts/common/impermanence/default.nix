# https://grahamc.com/blog/erase-your-darlings/
{ lib, pkgs, ... }:

{
  boot.initrd.postDeviceCommands = lib.mkAfter ''
    # Mount existing filesystem in temporary directory
    ${pkgs.coreutils}/bin/mkdir /btrfs_tmp
    ${pkgs.util-linux}/bin/mount -t btrfs /dev/mapper/crypted /btrfs_tmp

    # Backup old root (if it exists) in old_roots/<last_root_modification_datetime>
    if test -e /btrfs_tmp/root; then
      ${pkgs.coreutils}/bin/mkdir -p /btrfs_tmp/old_roots
      timestamp=$(${pkgs.coreutils}/bin/date --date="@$(${pkgs.coreutils}/bin/stat -c %Y /btrfs_tmp/root)" "+%Y%m%d_%H%M%S")
      ${pkgs.coreutils}/bin/mv /btrfs_tmp/root /btrfs_tmp/old_roots/$timestamp
    fi

    # Function to delete btrfs subvolumes recursively
    delete_subvolume_recursively() {
      IFS=$'\n'

      # Get the list of nested subvolumes to delete them recursively
      for i in $(${pkgs.btrfs-progs}/bin/btrfs subvolume list -o "$1" | ${pkgs.coreutils}/bin/cut -d' ' -f9-); do
        delete_subvolume_recursively "/btrfs_tmp/$i"
      done

      # Delete subvolume
      ${pkgs.btrfs-progs}/bin/btrfs subvolume delete "$1"
    }

    # Unclutter old roots by removing all but the last 30 days
    for i in $(${pkgs.findutils}/bin/find /btrfs_tmp/old_roots/ -maxdepth 1 -mtime +30); do
      delete_subvolume_recursively "$i"
    done

    # Create new subvolume in place of old one
    ${pkgs.btrfs-progs}/bin/btrfs subvolume create /btrfs_tmp/root
    ${pkgs.util-linux}/bin/umount /btrfs_tmp
  '';

  # Mark persistent storage as needed for boot
  fileSystems."/persist".neededForBoot = true;

  environment.persistence."/persist" = {
    # Hide the bind mounts to persistent storage
    hideMounts = true;

    # Directories to persist
    # Can be:
    # - a string representing the path to the directory to persist
    # - an attribute set defining further options:
    #   - directory: path to the directory to persist
    #   - persistentStoragePath: path in persistent storage
    #   - user: user owning the directory (only effective on directory creation)
    #   - group: group owning the directory (only effective on directory creation)
    #   - mode: directory permissions (only effective on directory creation)
    directories = [];

    # Files to persist
    # Can be:
    # - a string representing the path to the file to persist
    # - an attribute set defining further options:
    #    - file: path to the file to persist
    #    - persistentStoragePath: path in persistent storage
    #    - parentDirectory: permissions to apply to the parent directory of the file
    #      - mode: see directories.mode
    #      - user: see directories.user
    #      - group: see directories.group
    files = [
      "/etc/ssh/ssh_host_rsa_key"
      "/etc/ssh/ssh_host_ed25519_key"
    ];

    # Persistence options for directories and files in given user home directory
    # Options are the same as the root attribute set 'directories' and 'files' attributes
    # Paths are automatically prefixed with the user's home directory
    # If user directory is not '/home/<username>', set it explicitly with the 'home' attribute
    #users.<username> = {};
  };
}

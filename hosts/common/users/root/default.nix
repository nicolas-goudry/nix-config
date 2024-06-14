{ config, lib, ... }:

{
  # Define sops source for root user password
  sops.secrets.root-password = {
    sopsFile = ./secrets.yaml;
    neededForUsers = true;
  };

  # Define user (note: use mkpasswd to create password hash)
  users.users.root = {
    # Required for warningless ISO build since base installation cd-dvd set it to an empty string
    # https://github.com/NixOS/nixpkgs/blob/nixos-24.05/nixos/modules/profiles/installation-device.nix#L40
    initialHashedPassword = lib.mkForce null;

    hashedPasswordFile = config.sops.secrets.root-password.path;

    # Set authorized SSH keys
    #openssh.authorizedKeys.keys = [
    #  "<key-here>"
    #];
  };
}

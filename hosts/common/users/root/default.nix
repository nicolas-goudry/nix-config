{ config, ... }:

{
  # Define sops source for root user password
  sops.secrets.root-password = {
    sopsFile = ./secrets.yaml;
    neededForUsers = true;
  };

  # Define user (note: use mkpasswd to create password hash)
  users.users.root = {
    hashedPasswordFile = config.sops.secrets.root-password.path;
    #openssh.authorizedKeys.keys = [
    #  "<key-here>"
    #];
  };
}

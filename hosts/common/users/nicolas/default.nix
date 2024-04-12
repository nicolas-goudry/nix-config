{ config, ... }:

{
  # Define sops source for user password
  sops.secrets.nicolas-password = {
    sopsFile = ./secrets.yaml;
    neededForUsers = true;
  };

  # TODO: move to home-manager
  #environment.systemPackages = (with pkgs; [
  #  bitwarden-cli
  #] ++ lib.optionals isWorkstation [
  #  bitwarden-desktop
  #  brave
  #  chromium
  #  firefox
  #  opera
  #  vivaldi
  #]);

  # Define user (note: use mkpasswd to create password hash)
  users.users.nicolas = {
    description = "Nicolas Goudry";
    hashedPasswordFile = config.sops.secrets.nicolas-password.path;
  };
}

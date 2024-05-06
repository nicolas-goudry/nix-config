{ config, outputs, username, ... }:

{
  # Define sops source for user password
  sops.secrets = outputs.libx.mkUserSecrets {
    inherit username;

    sopsFile = ./secrets.yaml;
    secrets = [
      { name = "nicolas-password"; neededForUsers = true; }
      { name = "nix-access-tokens"; }
      { name = "ssh-keys_aur"; dir = ".ssh"; file = "aur"; }
      { name = "ssh-keys_aur.pub"; dir = ".ssh"; file = "aur.pub"; }
      { name = "ssh-keys_id_rsa_goudry.nicolas@gmail.com"; dir = ".ssh"; file = "id_rsa_goudry.nicolas@gmail.com"; }
      { name = "ssh-keys_id_rsa_goudry.nicolas@gmail.com.pub"; dir = ".ssh"; file = "id_rsa_goudry.nicolas@gmail.com.pub"; }
    ];
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

  nix.extraOptions = ''
    !include ${config.sops.secrets.nix-access-tokens.path}
  '';

  # Define user (note: use mkpasswd to create password hash)
  users.users.nicolas = {
    description = "Nicolas Goudry";
    hashedPasswordFile = config.sops.secrets.nicolas-password.path;
  };
}

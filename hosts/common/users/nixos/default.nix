{
  desktop,
  isInstall,
  isWorkstation,
  lib,
  pkgs,
  ...
}:

let
  # Precompute predicates
  isWorkstationISO = !isInstall && isWorkstation;

  # Autostart Ghostty
  ghostty-autostart = pkgs.makeAutostartItem {
    name = "com.mitchellh.ghostty";
    package = pkgs.ghostty;
  };

  user = builtins.baseNameOf (builtins.toString ./.);
in
{
  # Declare user without password
  users.users.${user} = {
    description = "NixOS";
    extraGroups = [ "wheel" ];
  };

  # Add ISO install packages
  environment = {
    systemPackages =
      lib.optionals (!isInstall) [
        ghostty-autostart
      ]
      ++ lib.optional isWorkstationISO pkgs.gparted;
  };

  # Enable autologin
  services.displayManager.autoLogin = lib.mkIf isWorkstationISO {
    inherit user;

    enable = lib.mkForce true;
  };

  system = {
    # Set OS edition
    nixos.variant_id = lib.mkIf isWorkstationISO (lib.mkForce "${desktop}");

    # Set state version to current nixpkgs release number
    # https://ryantm.github.io/nixpkgs/functions/library/trivial/#function-library-lib.trivial.release
    stateVersion = lib.mkIf (!isInstall) (lib.mkForce lib.trivial.release);
  };

  systemd.tmpfiles = lib.mkIf isWorkstationISO {
    rules = [
      # Initialize dummy ZSH config file to avoid config prompt
      "f /home/${user}/.zshrc 0755 ${user} users - # dummy"
      # Initialize empty wifi secrets file to prevent wpa_supplicant to fail
      # This is needed since on ISO images there are no valid keys to decrypt wifi secrets
      "d /run/secrets 0755 root root"
      "f /run/secrets/wifi 0755 root root"
    ];
  };
}

{ desktop, hostname, inputs, lib, pkgs, platform, username, ... }:

let
  # Precompute predicates
  isInstall = builtins.substring 0 4 hostname != "iso-";
  isWorkstation = if (desktop != null) then true else false;
  isWorkstationISO = !isInstall && isWorkstation;

  # Install script
  install-system = pkgs.writeScriptBin "install-system" (builtins.readFile ./install.sh);

  # Autostart alacritty
  alacritty-autostart = pkgs.makeAutostartItem { name = "Alacritty"; package = pkgs.alacritty; };
in
{
  # Declare user without password
  users.users.${username}.description = "NixOS";

  # Add ISO install packages
  environment = {
    systemPackages = lib.optionals (!isInstall) [
      inputs.disko.packages.${platform}.default
      alacritty-autostart
      install-system
    ]
    # Those are needed for install.sh
    ++ (with pkgs; [
      jq
      rsync
      yq
    ] ++ lib.optional isWorkstationISO pkgs.gparted);
  };

  # Set “favorite” apps shown in overview dock
  programs.dconf.profiles.user.databases = [{
    settings = lib.mkIf isWorkstationISO {
      "org/gnome/shell" = {
        favorite-apps = [ "io.calamares.calamares.desktop" "gparted.desktop" "Alacritty.desktop" "nixos-manual.desktop" ];
      };
    };
  }];

  # Enable autologin
  services.xserver.displayManager.autoLogin = lib.mkIf isWorkstationISO {
    enable = lib.mkForce true;
    user = "${username}";
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
      "f /home/${username}/.zshrc 0755 ${username} users - # dummy"
      # Initialize empty wifi secrets file to prevent wpa_supplicant to fail
      # This is needed since on ISO images there are no valid keys to decrypt wifi secrets
      "d /run/secrets 0755 root root"
      "f /run/secrets/wifi 0755 root root"
    ];
  };
}

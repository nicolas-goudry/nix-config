{ desktop, hostname, lib, pkgs, username, ... }:

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
      alacritty-autostart
      install-system
      #inputs.disko.packages.${platform}.default
      pkgs.jq
      pkgs.yq
    ] ++ lib.optionals isWorkstationISO [
      pkgs.gparted
    ];
  };

  # Set “favorite” apps shown in dock
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

  # Initialize dummy ZSH config file to avoid no config prompt
  systemd.tmpfiles = lib.mkIf isWorkstationISO {
    rules = [
      "f /home/${username}/.zshrc 0755 ${username} users - # dummy"
    ];
  };
}

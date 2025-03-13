{
  config,
  desktop,
  lib,
  pkgs,
  platform,
  ...
}:

let
  desktopString = if builtins.isNull desktop then "console" else desktop;
in
{
  # Create a bootable ISO image with bcachefs
  # https://wiki.nixos.org/wiki/Bcachefs
  boot.supportedFilesystems = [ "bcachefs" ];

  # Since we use bcachefs we need those packages
  environment.systemPackages = with pkgs; [
    unstable.bcachefs-tools
    keyutils
  ];

  # Customize ISO file name
  isoImage.isoName = lib.mkForce "custom-nixos-${desktopString}-${config.system.nixos.label}-${platform}.iso";

  # Always force enable wireless on ISOs to allow install script to clone configuration from git
  # See hosts/common/users/nixos/install.sh for details
  networking.wireless.enable = lib.mkForce true;

  nixpkgs.overlays = [
    (_final: _prev: {
      # Prevent mbrola-voices (~650MB) from being on the live media
      espeak = _prev.espeak.override {
        mbrolaSupport = false;
      };
    })
  ];
}

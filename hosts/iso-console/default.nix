{ config, desktop, lib, pkgs, platform, ... }:

let
  desktopString = if builtins.isNull desktop then "console" else desktop;
in
{
  # Create a bootable ISO image with bcachefs
  # - https://nixos.wiki/wiki/Bcachefs
  boot.supportedFilesystems = [ "bcachefs" ];

  # Since we use bcachefs we need those packages
  environment.systemPackages = with pkgs; [
    unstable.bcachefs-tools
    keyutils
  ];

  # Customize ISO file name
  isoImage.isoName = lib.mkForce "custom-nixos-${desktopString}-${config.system.nixos.label}-${platform}.iso";

  # Always enable wireless on ISOs to allow install script to clone configuration
  networking.wireless.enable = true;

  nixpkgs.overlays = [
    (_final: _prev: {
      # Prevent mbrola-voices (~650MB) from being on the live media
      espeak = _prev.espeak.override {
        mbrolaSupport = false;
      };

      # Disable ZFS as it cannot be used with latest linux kernel required by the common hosts configuration. This is a
      # workaround since we cannot remove the 'zfs' string from 'supportedFilesystems'.
      # - https://github.com/NixOS/nixpkgs/blob/23.11/nixos/modules/installer/cd-dvd/installation-cd-minimal-new-kernel-no-zfs.nix
      # TODO: change boot.supportedFilesystems to an attrset when 24.05 is out.
      zfs = _prev.zfs.overrideAttrs (_: {
        meta.platforms = [ ];
      });
    })
  ];
}

# Brand: Dell
# Model: XPS 15 7590
# CPU  : Intel i9-9980HK (16) @ 5GHz
# RAM  : 64GB
# GPU  : NVIDIA GeForce GTX 1650M 4GB
# Disk : Toshiba XG5-P KXG50PNV2T04 2TB

{ inputs, ... }:

{
  imports = [
    # nixos-hardware
    inputs.hardware.nixosModules.dell-xps-15-7590-nvidia
    inputs.hardware.nixosModules.common-gpu-intel-disable

    # Configure wireless networks
    ../common/networks/casa.nix
    ../common/networks/gplus.nix
    ../common/networks/wojo.nix

    # Configure printers
    ../common/printers/casa.nix
  ];

  boot = {
    initrd = {
      availableKernelModules = [
        "xhci_pci"
        "ahci"
        "nvme"
        "usb_storage"
        "usbhid"
        "sd_mod"
        "rtsx_pci_sdmmc"
      ];

      luks.devices."luks-876741b6-2750-4975-abf1-1ef0e7cb5169" = {
        device = "/dev/disk/by-uuid/876741b6-2750-4975-abf1-1ef0e7cb5169";
      };
    };
  };

  # TODO: replace by disko setup?
  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/8a70016a-791d-4b9b-9ffd-c77a920995fc";
      fsType = "ext4";
    };

    "/boot" = {
      device = "/dev/disk/by-uuid/78D8-51C8";
      fsType = "vfat";
    };
  };

  # Enable wireless networks
  networking.wireless.enable = true;
}

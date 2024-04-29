# Brand: Gigabyte
# Model: Aero 15
# CPU  : i7-7700HQ (8) @ 2.8GHz
# RAM  : 16GB
# GPU  : NVIDIA GeForce GTX 1060 6GB
# Disk : Crucial CT525M 525GB

{ inputs, ... }:

{
  imports = [
    inputs.hardware.nixosModules.common-cpu-intel-kaby-lake
    inputs.hardware.nixosModules.common-gpu-nvidia
    inputs.hardware.nixosModules.common-pc-laptop
    inputs.hardware.nixosModules.common-pc-laptop-ssd

    # Disko configuration
    ./disks.nix

    # Erase your darlings
    ../common/impermanence

    # Configure wireless networks
    ../common/networks/casa.nix

    # Configure printers
    ../common/printers/casa.nix
  ];

  # Enable wireless networks
  networking.wireless.enable = true;

  boot = {
    kernelModules = [ "kvm-intel" ];

    initrd = {
      availableKernelModules = [
        "xhci_pci"
        "ahci"
        "usb_storage"
        "usbhid"
        "sd_mod"
      ];
    };
  };

  hardware.nvidia.prime = {
    intelBusId = "PCI:0:2:0";
    nvidiaBusId = "PCI:1:0:0";
  };
}

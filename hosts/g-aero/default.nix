# Brand: Gigabyte
# Model: Aero 15
# CPU  : i7-7700HQ (8) @ 2.8GHz
# RAM  : 16GB
# GPU  : NVIDIA GeForce GTX 1060 6GB
# Disk : Crucial CT525M 525GB

{
  imports = [
    # Disko configuration
    ./disks.nix

    # Configure wireless networks
    ../common/networks/casa.nix

    # Configure printers
    ../common/printers/casa.nix
  ];

  boot = {
    initrd = {
      availableKernelModules = [
        "xhci_pci"
        "ahci"
        "usb_storage"
        "usbhid"
        "sd_mod"
      ];
    };

    kernelModules = [
      "kvm-intel"
    ];
  };

  # Enable wireless networks
  networking.wireless.enable = true;
}

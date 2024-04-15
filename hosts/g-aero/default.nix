# Gigabyte Aero 15

{
  imports = [
    # Disko configuration
    ./disks.nix

    # Configure wireless networks
    ../common/shelf/networks/casa.nix

    # Configure printers
    ../common/shelf/printers/casa.nix
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

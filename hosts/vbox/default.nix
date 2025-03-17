# VirtualBox VM

{
  imports = [
    ./disks.nix
  ];

  boot = {
    initrd = {
      availableKernelModules = [
        "ata_piix"
        "ahci"
        "ohci_pci"
        "ehci_pci"
        "sd_mod"
        "sr_mod"
      ];
    };
  };

  virtualisation.virtualbox.guest.enable = true;
}

{
  disko.devices = {
    disk = {
      sda = {
        type = "disk";
        # From target host run 'lsblk' to get disk name
        # Then run 'ls -la /dev/disk/by-path | grep <disk-name>'
        device = "/dev/disk/by-path/pci-0000:00:17.0-ata-4.0";

        content = {
          type = "gpt";

          partitions = {
            ESP = {
              type = "EF00";
              name = "esp";
              end = "1024M";

              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "defaults" "umask=0077" ];
              };
            };

            root = {
              name = "root";
              size = "100%";

              content = {
                type = "luks";
                name = "crypted";
                settings.allowDiscards = true;
                passwordFile = "/tmp/data.passwordFile";

                content = {
                  type = "filesystem";
                  format = "bcachefs";
                  mountpoint = "/";
                  mountOptions = [ "defaults" ];
                };
              };
            };
          };
        };
      };
    };
  };
}

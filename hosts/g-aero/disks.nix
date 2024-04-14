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
              start = "0%";
              end = "1024MiB";

              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "defaults" "umask=0077" ];
              };
            };

            root = {
              name = "root";
              start = "1024MiB";
              end = "100%";

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

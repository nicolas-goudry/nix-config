{
  disko.devices = {
    disk = {
      sda = {
        type = "disk";
        # From target host run 'lsblk' to get disk name
        # Then run 'ls -la /dev/disk/by-path | grep <disk-name>'
        device = "/dev/disk/by-path/pci-0000:00:0d.0-ata-1.0";

        content = {
          type = "gpt";

          partitions = {
            ESP = {
              type = "EF00";
              end = "1G";

              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                # Set permission mask (rwx to owner only)
                mountOptions = [
                  "defaults"
                  "umask=0077"
                ];
              };
            };

            root = {
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

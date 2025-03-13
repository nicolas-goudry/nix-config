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

            luks = {
              size = "100%";

              content = {
                type = "luks";
                name = "crypted";
                settings.allowDiscards = true;
                passwordFile = "/tmp/data.passwordFile";

                content = {
                  type = "btrfs";

                  # mkfs.btrfs extra arguments (https://btrfs.readthedocs.io/en/latest/mkfs.btrfs.html)
                  # - "-f": force overwrite block devices when existing fs is detected
                  extraArgs = [ "-f" ];

                  # btrfs mount options: https://btrfs.readthedocs.io/en/latest/btrfs-man5.html#mount-options
                  subvolumes = {
                    root = {
                      mountpoint = "/";
                      mountOptions = [
                        "compress=zstd"
                        "noatime"
                      ];
                    };

                    home = {
                      mountpoint = "/home";
                      mountOptions = [
                        "compress=zstd"
                        "noatime"
                      ];
                    };

                    nix = {
                      mountpoint = "/nix";
                      mountOptions = [
                        "compress=zstd"
                        "noatime"
                      ];
                    };

                    persist = {
                      mountpoint = "/persist";
                      mountOptions = [
                        "compress=zstd"
                        "noatime"
                      ];
                    };
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}

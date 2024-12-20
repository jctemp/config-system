# We have to set the `imageSize` for testing. Otherwise, the allocated
# disk is too small for partitioning, leading to alignment issues.
# References:
# - https://github.com/nix-community/disko/blob/master/docs/disko-images.md
# - https://github.com/nix-community/disko/blob/master/lib/types/disk.nix
{
  config,
  lib,
  pkgs,
  device,
  ...
}:
{
  boot = {
    kernelPackages = lib.mkForce pkgs.linuxPackages;
    supportedFilesystems = [ "zfs" ];
    initrd.postDeviceCommands = lib.mkAfter (
      builtins.concatStringsSep "; " (
        lib.map (sn: "zfs rollback -r ${sn}") [
          "rpool/local/root@blank"
        ]
      )
    );
  };

  services.zfs = {
    autoScrub.enable = true;
    autoSnapshot.enable = true;
    trim.enable = true;
    trim.interval = "weekly";
  };

  environment.etc = {
    "NetworkManager/system-connections" = {
      source = "/persist/etc/NetworkManager/system-connections/";
    };
  };

  systemd.tmpfiles.rules =
    if config.module.multimedia.bluetoothSupport then
      [
        # https://www.freedesktop.org/software/systemd/man/latest/tmpfiles.d.html
        "L /var/lib/bluetooth - - - - /persist/var/lib/bluetooth"
      ]
    else
      [ ];

  disko.devices = {
    disk = {
      main = {
        inherit device;
        imageName = "nixos-disko-root-zfs";
        imageSize = "32G";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            boot = {
              label = "BOOT";
              size = "1M";
              type = "EF02"; # for GRUB MBR
            };
            esp = {
              label = "EFI";
              size = "2G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };
            encryptedSwap = {
              size = "128M";
              content = {
                type = "swap";
                randomEncryption = true;
                priority = 100; # prefer to encrypt as long as we have space for it
              };
            };
            swap = {
              size = "4G";
              content = {
                type = "swap";
                discardPolicy = "both";
                resumeDevice = true;
              };
            };
            root = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "rpool";
              };
            };
          };
        };
      };
    };

    zpool = {
      rpool = {
        type = "zpool";
        mountpoint = "/";
        options = {
          ashift = "12";
          autotrim = "on";
        };
        rootFsOptions = {
          acltype = "posixacl";
          canmount = "off";
          dnodesize = "auto";
          normalization = "formD";
          relatime = "on";
          xattr = "sa";
          compression = "zstd";
        };
        datasets = {
          local = {
            type = "zfs_fs";
            options.mountpoint = "none";
          };
          "local/root" = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
            mountpoint = "/";
            postCreateHook = ''
              zfs list -t snapshot -H -o name | grep -E '^rpool/local/root@blank$' \
              || zfs snapshot rpool/local/root@blank
            '';
          };
          "local/nix" = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
            mountpoint = "/nix";
          };
          safe = {
            type = "zfs_fs";
            options.mountpoint = "none";
          };
          "safe/home" = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
            mountpoint = "/home";
          };
          "safe/persist" = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
            mountpoint = "/persist";
          };
        };
      };
    };
  };
}

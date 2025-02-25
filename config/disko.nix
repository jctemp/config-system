# We have to set the `imageSize` for testing. Otherwise, the allocated
# disk is too small for partitioning, leading to alignment issues.
# References:
# - https://github.com/nix-community/disko/blob/master/docs/disko-images.md
# - https://github.com/nix-community/disko/blob/master/lib/types/disk.nix
{
  inputs,
  config,
  lib,
  pkgs,
  ...
}: let
  loaderType = config.hostSpec.loader;
  device = config.hostSpec.device;
  safePath = config.hostSpec.safePath;
in {
  imports = [
    inputs.disko.nixosModules.disko
    inputs.nixos-facter-modules.nixosModules.facter
    inputs.impermanence.nixosModules.impermanence
  ];

  boot = {
    kernelPackages = lib.mkForce pkgs.linuxPackages;

    loader = {
      grub = lib.mkIf (loaderType == "grub") {
        enable = true;
        forceInstall = true;
        efiSupport = true;
        configurationLimit = 5;
        zfsSupport = true;
        inherit device;
      };

      systemd-boot = lib.mkIf (loaderType == "systemd") {
        enable = true;
        configurationLimit = 5;
      };

      efi.canTouchEfiVariables = loaderType == "systemd";
    };

    supportedFilesystems = [
      "btrfs"
      "reiserfs"
      "vfat"
      "f2fs"
      "xfs"
      "ntfs"
      "cifs"
      "zfs"
    ];

    binfmt.emulatedSystems = [
      "x86_64-windows"
      "aarch64-linux"
    ];

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

  environment.persistence.${safePath} = {
    enable = true;
    hideMounts = true;
    directories =
      [
        "/var/lib/systemd/coredump"
        "/var/lib/nixos"
        "/etc/NetworkManager/system-connections"
      ]
      ++ (
        if config.modules.hardware.bluetooth.enable
        then [
          "/var/lib/bluetooth"
        ]
        else []
      );
  };

  # need to set manually here because disko does not have this flag
  fileSystems.${safePath}.neededForBoot = true;
  facter.reportPath = "${inputs.self}/config/hosts/${config.hostSpec.system}.${config.hostSpec.hostName}/facter.json";

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
                mountOptions = ["umask=0077"];
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
            mountpoint = safePath;
          };
        };
      };
    };
  };
}

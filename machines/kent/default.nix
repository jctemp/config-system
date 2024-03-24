{pkgs, lib, ...}: {
  imports = [./hardware-configuration.nix];

  hosts = {
    nvidia.enable = false;
    virtualisation = {
      docker.enable = true;
      libvirt.enable = false;
    };
  };

  boot = {
    kernelPackages = lib.mkDefault pkgs.zfs.latestCompatibleLinuxPackages;
    supportedFilesystems = lib.mkForce ["btrfs" "reiserfs" "vfat" "f2fs" "xfs" "ntfs" "cifs" "zfs"];
    initrd.postDeviceCommands = lib.mkAfter ''
      zfs rollback -r rpool/local/root@blank
    '';
  };

  services.zfs = {
    autoScrub.enable = true;
    autoSnapshot.enable = true;
  };

  environment.etc = {
    "NetworkManager/system-connections" = {
      source = "/persist/etc/NetworkManager/system-connections/";
    };
  };

  systemd.tmpfiles.rules = [
    # https://www.freedesktop.org/software/systemd/man/latest/tmpfiles.d.html
    # create symlink to
    "L /var/lib/bluetooth - - - - /persist/var/lib/bluetooth"
  ];

  users.users.root = {
    password = "";
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDKzE8tMyXIM8Fq/9/ubwP9tlqL0WTlZ7NBF4pcO/p3T7AZD2W9W2c/tzbnk/GeqOKEF94VLO1dmHOAUW3WjbjgdtLhnVetSLTfYYUYYSPueX56FBHN8734kQRaYQ0jGMTA8TnH+dnZo6N1wdZZx/yIEyCQ4+N6EdNGxq9Y35joepubZL3LuaHWJj3BTswYorrDwRvkVaEFSS3CLGHWxOmey7dt7GAvKz2rod6uA4jZjbXzFSfMdyXq7/t1uclxHYPwd3imoMCtf67qn/qRs7S6v6vE3d5+XnMYMjDKAjv9uPw2O3DpdEgCfgUIkDYJ6u7aJ9DkLRpTNm2XVTKXqcWwVyKvR8SiprchJGge+mSC+GIooHvylzPxR+NyI/iZIcR2HO4kxHymTYoV4NEAr5LCT5Vew9QyIB9nyf5UJt4zYr9CJ8gCsK/oBeOBJeeAzZuH6/A4Zxt8gt6vtJ46eXk+gHFsF+YODtBMHrSR0TGODcWu3oz+Jmm+LtPbbbUR75kWjvnPr+H8jmgo3U/DGFHZij1XpGRapr7xMHRlah6lE7sIWk2Kb4zAMvw8yZqrMd0wA+UwpVYgGIZhjHP2SklwZig9hLjAQvXsWK2fbz6vvARWQ+6jRSMvYDEWf9LUP86gj+q+oKxkcQLad43ygzNK9RRBCYzSDNt8uB23DrXnkw== openpgp:0x63921A88"
    ];
  };

  services = {
    openssh = {
      enable = true;
      banner = ''
        ███╗   ██╗ ██╗ ██╗  ██╗  ██████╗  ███████╗
        ████╗  ██║ ██║ ╚██╗██╔╝ ██╔═══██╗ ██╔════╝
        ██╔██╗ ██║ ██║  ╚███╔╝  ██║   ██║ ███████╗
        ██║╚██╗██║ ██║  ██╔██╗  ██║   ██║ ╚════██║
        ██║ ╚████║ ██║ ██╔╝ ██╗ ╚██████╔╝ ███████║
        ╚═╝  ╚═══╝ ╚═╝ ╚═╝  ╚═╝  ╚═════╝  ╚══════╝
        Powered by NixOS
      '';
      allowSFTP = true;
      openFirewall = true;
    };
  };
}

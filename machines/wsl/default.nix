{self, pkgs, lib, ...}: 
with lib; let
  usbipd-win-auto-attach = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/dorssel/usbipd-win/v3.1.0/Usbipd/wsl-scripts/auto-attach.sh";
    hash = "sha256-KJ0tEuY+hDJbBQtJj8nSNk17FHqdpDWTpy9/DLqUFaM=";
  };
in
{
  imports = [
    ./hardware-configuration.nix
    "${self}/modules/base.nix"
  ];

  wsl = {
    enable = true;
    wslConf.automount.root = "/mnt";
    wslConf.interop.appendWindowsPath = false;
    wslConf.network.generateHosts = false;
    defaultUser = username;
    startMenuLaunchers = true;

    # Enable integration with Docker Desktop (needs to be installed)
    docker-desktop.enable = false;

    # Yubikey stuff
    usbip = {
      enable = true;
      # Replace this with the BUSID for your Yubikey
      autoAttach = ["9-4"];
    };
  };

  virtualisation.docker = {
    enableOnBoot = true;
    autoPrune.enable = true;
  };

  services = {
    udev.extraRules = ''
        SUBSYSTEM=="usb", MODE="0666"
        KERNEL=="hidraw*", SUBSYSTEM=="hidraw", TAG+="uaccess", MODE="0666"
      '';
    pcscd.enable = true;
    vscode-server.enable = true;
  };

  systemd = {
    services."usbip-auto-attach@" = {
      description = "Auto attach device having busid %i with usbip";
      after = ["network.target"];

      scriptArgs = "%i";
      path = [pkgs.linuxPackages.usbip];

      script = ''
        busid="$1"
        ip="$(grep nameserver /etc/resolv.conf | cut -d' ' -f2)"

        echo "Starting auto attach for busid $busid on $ip."
        source ${usbipd-win-auto-attach} "$ip" "$busid"
      '';
    };

    targets.multi-user.wants = map (busid: "usbip-auto-attach@${busid}.service") cfg.autoAttach;
  };

  system.stateVersion = "23.11"; 
}

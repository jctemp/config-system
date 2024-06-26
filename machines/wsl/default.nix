{self, ...}: {
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
  };

  virtualisation.docker = {
    enableOnBoot = true;
    autoPrune.enable = true;
  };

  services.vscode-server.enable = true;

  system.stateVersion = "23.11"; 
}

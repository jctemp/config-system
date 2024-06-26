# canTouchEfiVariables = true;
# device = "nodev"
# zfsSupport = true;
# userName
# hostId
# hostName
{
  pkgs,
  userName,
  hostId,
  hostName,
  zfsSupport ? false,
  ...
}: {
  # ==== [ Nix ] ==============================================================

  nix = {
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };
    optimise = {
      automatic = true;
    };
    settings = {
      experimental-features = "nix-command flakes";
      auto-optimise-store = true;
      trusted-users = ["root" userName];
    };
  };

  # ==== [ ZFS ] ==============================================================

  services.zfs = {
    autoScrub.enable = zfsSupport;
    autoSnapshot.enable = zfsSupport;
  };

  # ==== [ Networking ] =======================================================

  networking = {
    inherit hostId hostName;
    wireless.enable = false;
    networkmanager.enable = true;
  };

  # ==== [ Internationalisation and Time ] ====================================

  time = {
    timeZone = "Europe/Berlin";
    hardwareClockInLocalTime = true; # for windoof
  };

  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = let
      extraLocale = "de_DE.UTF-8";
    in {
      LC_ADDRESS = extraLocale;
      LC_IDENTIFICATION = extraLocale;
      LC_MEASUREMENT = extraLocale;
      LC_MONETARY = extraLocale;
      LC_NAME = extraLocale;
      LC_NUMERIC = extraLocale;
      LC_PAPER = extraLocale;
      LC_TELEPHONE = extraLocale;
      LC_TIME = extraLocale;
    };
  };

  # ==== [ Virtualisation ] ===================================================

  virtualisation.libvirtd.enable = true;
  programs.virt-manager.enable = true;

  virtualisation.docker = {
    enable = true;
    rootless = {
      enable = true;
      setSocketVariable = true;
    };
  };

  # ==== [ PGP ] ==============================================================

  # Informs the environment that we are using GPG agent for SSH
  environment = {
    shellInit = ''
      export GPG_TTY="$(tty)"
      gpg-connect-agent /bye
      export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
      gpgconf --launch gpg-agent
    '';
    interactiveShellInit = ''
      export GPG_TTY="$(tty)"
      gpg-connect-agent /bye
      export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
      gpgconf --launch gpg-agent
    '';
  };

  programs = {
    fuse.userAllowOther = true;
    ssh.startAgent = false;
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
  };

  services = {
    udev = {
      enable = true;
      packages = [pkgs.yubikey-personalization];
    };
    pcscd.enable = true;
  };

  # ==== [ MISC ] =============================================================

  fonts.packages = [
    pkgs.dejavu_fonts
    pkgs.cm_unicode
    pkgs.libertine
    pkgs.roboto
    pkgs.noto-fonts
  ];

  users.users.${userName}.extraGroups = ["networkmanager"] ++ ["docker" "libvirtd"];

  environment.systemPackages =
    [pkgs.libguestfs]
    ++ [
      # GPG w/ Yubikey (Multiple keys)
      (pkgs.writeShellScriptBin "gpg-reset-yubikey-id" ''
        echo "Reset gpg to make new key available."
        set -x
        set -e
        ${pkgs.psmisc}/bin/killall gpg-agent
        rm -r ~/.gnupg/private-keys-v1.d/
        echo "Now the new key should work."
      '')

      # Defaults
      pkgs.curl
      pkgs.git
      pkgs.ripgrep
      pkgs.tree
      pkgs.wget

      # Yubikey
      pkgs.yubico-piv-tool
      pkgs.yubikey-manager
      pkgs.yubikey-manager-qt
      pkgs.yubikey-personalization
      pkgs.yubikey-personalization-gui
      pkgs.yubikey-touch-detector
      pkgs.yubioath-flutter

      # GPG
      pkgs.gnupg
      pkgs.pinentry

      # Further tools
      pkgs.paperkey
      pkgs.pcsctools
    ];

  environment.etc =
    if zfsSupport
    then {
      "NetworkManager/system-connections" = {
        source = "/persist/etc/NetworkManager/system-connections/";
      };
    }
    else {};
}

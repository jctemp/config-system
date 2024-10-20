{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.module.privacy;
in {
  options.module.privacy = {
    enable = lib.mkOption {
      default = true;
      defaultText = "true";
      description = "Whether to enable the module.";
      type = lib.types.bool;
    };
    supportYubikey = lib.mkOption {
      default = false;
      defaultText = "false";
      description = "Whether to enable YubiKey support. Substitutes SSH Agent.";
      type = lib.types.bool;
    };
  };

  config = lib.mkMerge [
    # GNU-PG
    (lib.mkIf cfg.enable {
      environment.systemPackages = [
        pkgs.gnupg
        pkgs.paperkey
      ];
      programs.ssh.startAgent = !cfg.supportYubikey;
    })
    # YubiKey
    (lib.mkIf (cfg.enable
      && cfg.supportYubikey) {
      environment.systemPackages = [
        # GPG w/ Yubikey (Multiple keys)
        (pkgs.writeShellScriptBin "gpg-reset-yubikey-id" ''
          echo "Reset gpg to make new key available."
          set -x
          set -e
          ${pkgs.psmisc}/bin/killall gpg-agent
          rm -r ~/.gnupg/private-keys-v1.d/
          echo "Now the new key should work."
        '')

        # Yubikey
        pkgs.yubioath-flutter
        pkgs.yubikey-manager
        pkgs.pam_u2f
      ];

      programs = {
        # Filesystem in Userspace; secure method for non privileged users to
        # create and mount their own filesystem
        fuse.userAllowOther = true;
        gnupg.agent = {
          enable = true;
          enableSSHSupport = true;
        };
      };

      services = {
        yubikey-agent.enable = true;
        udev.packages = [pkgs.yubikey-personalization];
        pcscd.enable = true;
      };
    })
  ];
}

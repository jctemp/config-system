{
  mergeHosts = configs:
    builtins.foldl' (hosts: host: hosts // host) {} configs;

  mkHost = args: {
    ${args.hostName} = args.nixpkgs.lib.nixosSystem {
      specialArgs = {
        inherit (args) self hostId hostName userName zfsSupport cudaSupport;
      } // (if args.boot then {
        inherit (args.boot) device canTouchEfiVariables;
      } else {});
      modules =
        [
          "${args.self}/machines/${args.hostName}"
          {
            nixpkgs.config.allowUnfree = true;
            system.stateVersion = args.stateVersion;
            users.users.${args.userName} = {
              hashedPassword = args.userPassword;
              isNormalUser = true;
              extraGroups = ["wheel"];
              openssh.authorizedKeys.keys = [args.userKey];
            };
          }
        ]
        ++ args.modules;
    };
  };
}

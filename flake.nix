{
  description = "NixOS system configuration";

  nixConfig.experimental-features = ["nix-command" "flakes"];

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";

    # Disk management
    disko = {
      url = "github:nix-community/disko/latest";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # State management
    impermanence.url = "github:nix-community/impermanence";

    # Hardware support
    nix-hardware.url = "github:NixOS/nixos-hardware";
    nixos-facter-modules.url = "github:numtide/nixos-facter-modules";
  };

  outputs = inputs: let
    mkSystem = hostName: system: extraModules:
      inputs.nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {inherit inputs;};
        modules =
          [
            ./modules
            ./hosts/${hostName}

            ./modules/disk-config.nix
            ./modules/user-config.nix

            ({...}: {
              modules.hostSpec.hostName = hostName;
              system.stateVersion = "24.11";
            })
          ]
          ++ extraModules;
      };

    mkEach = systems: func:
      inputs.nixpkgs.lib.genAttrs systems (system: func system);
    mkEachDefault = mkEach ["x86_64-linux"];
  in {
    nixosConfigurations = {
      desktop = mkSystem "desktop" "x86_64-linux" [];
      laptop = mkSystem "laptop" "x86_64-linux" [
        inputs.nix-hardware.nixosModules.microsoft-surface-common
      ];
      vm = mkSystem "vm" "x86_64-linux" [];
    };

    # Development utilities
    devShells = mkEachDefault (system: {
      default = let
        pkgs = import inputs.nixpkgs {inherit system;};
      in
        pkgs.mkShellNoCC {
          name = "system-config";
          packages = [
            pkgs.nix
            pkgs.git
            pkgs.nixfmt
          ];
        };
    });

    formatter = mkEachDefault (system: inputs.nixpkgs.legacyPackages.${system}.alejandra);
  };
}

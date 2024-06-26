{
  description = "NixOS system configuration";

  nixConfig = {
    experimental-features = ["nix-command" "flakes"];
    extra-substituters = ["https://cuda-maintainers.cachix.org"];
    extra-trusted-substituters = ["https://cuda-maintainers.cachix.org"];
    extra-trusted-public-keys = ["cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    flake-utils.url = "github:numtide/flake-utils";
    nix-hardware.url = "github:NixOS/nixos-hardware";
    nixos-wsl.url = "github:nix-community/NixOS-WSL";
    nixos-wsl.inputs.nixpkgs.follows = "nixpkgs";
    vscode-server.url = "github:nix-community/nixos-vscode-server";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    nix-hardware,
    nixos-wsl,
    vscode-server,
  }: let
    lib = import ./lib/utils.nix;

    userName = "temple";
    userPassword = "$y$j9T$C3qwfGNOj6WptYGkV9.jJ1$JkNh2o8AgBUzYt7n/HT8p/CMcJUn2OP0GkzmpdITuk2";
    userKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDKzE8tMyXIM8Fq/9/ubwP9tlqL0WTlZ7NBF4pcO/p3T7AZD2W9W2c/tzbnk/GeqOKEF94VLO1dmHOAUW3WjbjgdtLhnVetSLTfYYUYYSPueX56FBHN8734kQRaYQ0jGMTA8TnH+dnZo6N1wdZZx/yIEyCQ4+N6EdNGxq9Y35joepubZL3LuaHWJj3BTswYorrDwRvkVaEFSS3CLGHWxOmey7dt7GAvKz2rod6uA4jZjbXzFSfMdyXq7/t1uclxHYPwd3imoMCtf67qn/qRs7S6v6vE3d5+XnMYMjDKAjv9uPw2O3DpdEgCfgUIkDYJ6u7aJ9DkLRpTNm2XVTKXqcWwVyKvR8SiprchJGge+mSC+GIooHvylzPxR+NyI/iZIcR2HO4kxHymTYoV4NEAr5LCT5Vew9QyIB9nyf5UJt4zYr9CJ8gCsK/oBeOBJeeAzZuH6/A4Zxt8gt6vtJ46eXk+gHFsF+YODtBMHrSR0TGODcWu3oz+Jmm+LtPbbbUR75kWjvnPr+H8jmgo3U/DGFHZij1XpGRapr7xMHRlah6lE7sIWk2Kb4zAMvw8yZqrMd0wA+UwpVYgGIZhjHP2SklwZig9hLjAQvXsWK2fbz6vvARWQ+6jRSMvYDEWf9LUP86gj+q+oKxkcQLad43ygzNK9RRBCYzSDNt8uB23DrXnkw== openpgp:0x63921A88";
  in
    {
      nixosConfigurations = lib.mergeHosts [
        (lib.mkHost {
          inherit self nixpkgs userName userPassword userKey;
          hostId = "eeae2b1c";
          hostName = "sussex";
          cudaSupport = true;
          zfsSupport = true;
          boot = {
            device = "";
            canTouchEfiVariables = true;
          };
          stateVersion = "23.11";
          modules = [];
        })
        (lib.mkHost {
          inherit self nixpkgs userName userPassword userKey;
          hostId = "25365b33";
          hostName = "cornwall";
          cudaSupport = true;
          zfsSupport = true;
          boot = {
            device = "";
            canTouchEfiVariables = true;
          };
          stateVersion = "23.11";
          modules = [
            nix-hardware.nixosModules.microsoft-surface-common
          ];
        })
        (lib.mkHost {
          inherit self nixpkgs userName userPassword userKey;
          hostId = "917e1048";
          hostName = "kent";
          cudaSupport = false;
          zfsSupport = true;
          boot = {
            device = "/dev/sda";
            canTouchEfiVariables = false;
          };
          stateVersion = "23.11";
          modules = [];
        })
        (lib.mkHost {
          inherit self nixpkgs userName userPassword userKey;
          hostId = "134a1048";
          hostName = "wsl";
          cudaSupport = false;
          zfsSupport = false;
          stateVersion = "23.11";
          modules = [
            nixos-wsl.nixosModules.wsl
            vscode-server.nixosModules.default
          ];
        })
      ];
    }
    // (flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in {
      formatter = pkgs.alejandra;
      devShells.default = pkgs.mkShell {
        packages = with pkgs;
          [
            alejandra
            deadnix
            nil
            statix
          ]
          ++ (import ./lib/devshell.nix {inherit pkgs;});
      };
    }));
}

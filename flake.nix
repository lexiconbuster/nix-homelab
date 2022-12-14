{
  description = "NixOS configuration with flakes";

  nixConfig = {
    extra-substituers = [ "https://nix-community.cachix.org" ];
    extra-trusted-public-keys =
      [ "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=" ];
  };

  # nix flake update --recreate-lock-file
  inputs = {
    # Hyprland
    hyprland.url = "github:hyprwm/Hyprland";
    hyprwm-contrib.url = "github:hyprwm/contrib";

    # Nix
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    hardware.url = "github:badele/fork-nixos-hardware/dell-e5540";
    impermanence.url = "github:nix-community/impermanence";
    nur.url = "github:nix-community/NUR";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # flake part
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";

    sops-nix = {
      url = "github:mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Pure  base16-schemes color themes
    nix-colors.url = "github:misterio77/nix-colors";
  };

  outputs =
    { self
    , nixpkgs
    , flake-parts
    , ...
    } @ inputs:
    (flake-parts.lib.evalFlakeModule
      { inherit self; }
      {
        systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ];
        imports = [
          ./configurations.nix
        ];
        perSystem = { system, self', inputs', pkgs, ... }: {
          devShells.default = pkgs.mkShellNoCC {
            buildInputs = [
              pkgs.python3.pkgs.invoke
              pkgs.python3.pkgs.deploykit
              pkgs.age
              pkgs.sops
            ] ++ pkgs.lib.optional (pkgs.stdenv.isLinux) pkgs.mkpasswd;
          };
        };
        flake = {
          hydraJobs = nixpkgs.lib.mapAttrs' (name: config: nixpkgs.lib.nameValuePair "nixos-${name}" config.config.system.build.toplevel) self.nixosConfigurations // {
            devShells = self.devShells.x86_64-linux.default;
          };
        };
      }).config.flake;

}
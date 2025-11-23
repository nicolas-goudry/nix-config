{
  description = "G.Nix";

  inputs = {
    # https://nixos.org/manual/nixpkgs/stable/
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    # Also see the 'unstable-packages' overlay at 'overlays/default.nix'
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    catppuccin = {
      url = "github:catppuccin/nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Disk formatting and partitioning tool
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Beautiful wallpapers from Google Earth View
    earth-view = {
      url = "github:nicolas-goudry/earth-view";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Common hardware profiles
    hardware.url = "github:nixos/nixos-hardware";

    # Users home directory management
    # https://nix-community.github.io/home-manager/index.xhtml
    # https://nix-community.github.io/home-manager/options.xhtml
    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Persist important state
    impermanence.url = "github:nix-community/impermanence";

    # Weekly updated nix-index database
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Wrapper for OpenGL applications
    nixgl = {
      url = "github:nix-community/nixGL";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixkraken = {
      url = "github:nicolas-goudry/nixkraken";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Neovim the Nix way
    nixvim-config.url = "github:nicolas-goudry/nixvim-config";

    # Secrets OPerationS for Nix
    sops = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Theme framework
    stylix = {
      url = "github:danth/stylix/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Code linter and formatter
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      treefmt-nix,
      ...
    }@inputs:
    let
      inherit (self) outputs;

      # Supported systems
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
        # We also need this in order to be able to enable to support 32-bit applications
        "i686-linux"
      ];

      # https://wiki.nixos.org/wiki/FAQ/When_do_I_update_stateVersion
      stateVersion = "23.11";

      # Custom helpers library
      libx = import ./lib {
        inherit inputs outputs stateVersion;
        inherit (nixpkgs) lib;
      };

      # Small tool to iterate over each systems
      eachSystem = f: inputs.nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
      # Eval the treefmt modules from ./treefmt.nix
      treefmtEval = eachSystem (pkgs: treefmt-nix.lib.evalModule pkgs ./treefmt.nix);
    in
    {
      inherit libx;

      # Flake checks
      # Run with: nix flake check (use --keep-going=true to report as much as possible)
      checks = eachSystem (pkgs: {
        formatting = treefmtEval.${pkgs.stdenv.hostPlatform.system}.config.build.check self;
      });

      # Formatting style using treefmt-nix
      # Run with: nix fmt
      formatter = eachSystem (pkgs: treefmtEval.${pkgs.stdenv.hostPlatform.system}.config.build.wrapper);

      # Custom packages and overlays
      overlays = import ./overlays { inherit inputs outputs; };
      packages = eachSystem (
        pkgs:
        pkgs.lib.packagesFromDirectoryRecursive {
          inherit (pkgs) callPackage;
          directory = ./pkgs;
        }
      );

      # Custom modules
      nixosModules = import ./modules/nixos;
      homeManagerModules = import ./modules/home-manager;

      # NixOS configuration entrypoints
      nixosConfigurations = {
        # Live ISO
        # nix build '.#nixosConfigurations.<hostname>.config.system.build.isoImage'
        iso-console = libx.mkHost {
          hostname = "iso-console";
          username = "nixos";
        };
        iso-gnome = libx.mkHost {
          hostname = "iso-gnome";
          username = "nixos";
          desktop = "gnome";
        };
        # Workstations
        # sudo nixos-rebuild boot --flake '.#<hostname>'
        # sudo nixos-rebuild switch --flake '.#<hostname>'
        # nix build '.#nixosConfigurations.<hostname>.config.system.build.topLevel'
        g-xps = libx.mkHost {
          hostname = "g-xps";
          username = "nicolas";
          desktop = "gnome";
        };
        g-aero = libx.mkHost {
          hostname = "g-aero";
          username = "nicolas";
          desktop = "gnome";
        };
      };

      # Standalone home-manager configuration entrypoints (TODO: configs)
      # home-manager switch -b backup --flake '.#<username@hostname>'
      homeConfigurations = {
        # .iso images
        "nixos@iso-console" = libx.mkHome {
          hostname = "iso-console";
          username = "nixos";
        };
        "nixos@iso-gnome" = libx.mkHome {
          hostname = "iso-gnome";
          username = "nixos";
          desktop = "gnome";
        };
        # Workstations
        "nicolas@g-xps" = libx.mkHome {
          hostname = "g-xps";
          username = "nicolas";
          desktop = "gnome";
        };
        "nicolas@g-aero" = libx.mkHome {
          hostname = "g-aero";
          username = "nicolas";
          desktop = "gnome";
        };
      };
    };
}

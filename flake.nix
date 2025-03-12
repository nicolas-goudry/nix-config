{
  description = "G.Nix";

  inputs = {
    # https://nixos.org/manual/nixpkgs/stable/
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    # Also see the 'unstable-packages' overlay at 'overlays/default.nix'
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    # Common hardware profiles
    hardware.url = "github:nixos/nixos-hardware";

    # Persist important state
    impermanence.url = "github:nix-community/impermanence";

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

    # Users home directory management
    # https://nix-community.github.io/home-manager/index.xhtml
    # https://nix-community.github.io/home-manager/options.xhtml
    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Nix formatting pack
    # https://gerschtli.github.io/nix-formatter-pack/nix-formatter-pack-options.html
    nix-formatter-pack = {
      url = "github:Gerschtli/nix-formatter-pack";
      inputs.nixpkgs.follows = "nixpkgs";
    };

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

    # Neovim the Nix way
    nixvim-config.url = "github:nicolas-goudry/nixvim-config";

    # Secrets OPerationS for Nix
    sops = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self
    , nix-formatter-pack
    , nixpkgs
    , ...
    } @ inputs:
    let
      inherit (self) outputs;

      # https://wiki.nixos.org/wiki/FAQ/When_do_I_update_stateVersion
      stateVersion = "23.11";

      # Custom helpers library
      libx = import ./lib { inherit inputs outputs stateVersion; inherit (nixpkgs) lib; };
    in
    {
      # nix fmt
      formatter = libx.forAllSystems (system:
        nix-formatter-pack.lib.mkFormatter {
          pkgs = nixpkgs.legacyPackages.${system};
          config.tools = {
            deadnix.enable = true;
            nixpkgs-fmt.enable = true;
            statix.enable = true;
          };
        }
      );

      # Custom packages and overlays
      overlays = import ./overlays { inherit inputs; };
      packages = libx.forAllSystems (system: import ./pkgs nixpkgs.legacyPackages.${system});

      # Custom modules
      nixosModules = import ./modules/nixos;
      homeManagerModules = import ./modules/home-manager;

      # NixOS configuration entrypoints
      nixosConfigurations = {
        # Live ISO
        # nix build '.#nixosConfigurations.<hostname>.config.system.build.isoImage'
        iso-console = libx.mkHost { hostname = "iso-console"; username = "nixos"; };
        iso-gnome = libx.mkHost { hostname = "iso-gnome"; username = "nixos"; desktop = "gnome"; };
        # Workstations
        # sudo nixos-rebuild boot --flake '.#<hostname>'
        # sudo nixos-rebuild switch --flake '.#<hostname>'
        # nix build '.#nixosConfigurations.<hostname>.config.system.build.topLevel'
        g-xps = libx.mkHost { hostname = "g-xps"; username = "nicolas"; desktop = "gnome"; };
        g-aero = libx.mkHost { hostname = "g-aero"; username = "nicolas"; desktop = "gnome"; };
      };

      # Standalone home-manager configuration entrypoints (TODO: configs)
      # home-manager switch -b backup --flake '.#<username@hostname>'
      homeConfigurations = {
        # .iso images
        "nixos@iso-console" = libx.mkHome { hostname = "iso-console"; username = "nixos"; };
        "nixos@iso-gnome" = libx.mkHome { hostname = "iso-gnome"; username = "nixos"; desktop = "gnome"; };
        # Workstations
        "nicolas@g-xps" = libx.mkHome { hostname = "g-xps"; username = "nicolas"; desktop = "gnome"; };
        "nicolas@g-aero" = libx.mkHome { hostname = "g-aero"; username = "nicolas"; desktop = "gnome"; };
        "nicolas@g-ns" = libx.mkHome { hostname = "g-ns"; username = "nicolas"; desktop = "gnome"; };
      };
    };
}

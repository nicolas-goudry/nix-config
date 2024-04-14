{
  description = "G.Nix";

  inputs = {
    # https://nixos.org/manual/nixpkgs/stable/
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    # Also see the 'unstable-packages' overlay at 'overlays/default.nix'
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    # https://nix-community.github.io/home-manager/index.xhtml
    # https://nix-community.github.io/home-manager/options.xhtml
    home-manager = {
      url = "github:nix-community/home-manager/release-23.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hardware.url = "github:nixos/nixos-hardware";

    sops = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # https://gerschtli.github.io/nix-formatter-pack/nix-formatter-pack-options.html
    nix-formatter-pack = {
      url = "github:Gerschtli/nix-formatter-pack";
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

      # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
      stateVersion = "23.11";

      # Custom helpers library
      libx = import ./lib { inherit inputs outputs stateVersion; };
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
      packages = libx.forAllSystems (system:
        let pkgs = nixpkgs.legacyPackages.${system};
        in import ./pkgs { inherit pkgs; }
      );

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

      # Standalone home-manager configuration entrypoints
      # nix run 'nixpkgs#home-manager' -- switch -b backup --flake '.#<username@hostname>'
      homeConfigurations = {
        # .iso images
        "nixos@iso-console" = libx.mkHome { hostname = "iso-console"; username = "nixos"; };
        "nixos@iso-gnome" = libx.mkHome { hostname = "iso-gnome"; username = "nixos"; desktop = "gnome"; };
        # Workstations
        "nicolas@g-xps" = libx.mkHome { hostname = "g-xps"; username = "nicolas"; desktop = "gnome"; };
      };
    };
}

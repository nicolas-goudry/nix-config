{ inputs, outputs, stateVersion, ... }:

{
  # Helper function for generating home-manager configs
  mkHome =
    { hostname
    , username
    , desktop ? null
    , platform ? "x86_64-linux"
    }: inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = inputs.nixpkgs.legacyPackages.${platform};

      extraSpecialArgs = {
        inherit inputs outputs desktop hostname platform username stateVersion;
      };

      # Common home-manager configuration
      modules = [ ../users ];
    };

  # Helper function for generating host configs
  mkHost =
    { hostname
    , username
    , desktop ? null
    , platform ? "x86_64-linux"
    }: inputs.nixpkgs.lib.nixosSystem {
      specialArgs = {
        inherit inputs outputs desktop hostname platform username stateVersion;
      };

      modules =
        let
          # If the hostname starts with "iso-", generate an ISO image
          isISO = if (builtins.substring 0 4 hostname == "iso-") then true else false;
          cd-dvd =
            if (desktop == null) then
              "${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal-new-kernel-no-zfs.nix"
            else
              "${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-graphical-base.nix";
        in
        # Common host configuration merged with ISO installer if needed
        [ ../hosts ] ++ (inputs.nixpkgs.lib.optionals isISO [ cd-dvd ]);
    };

  # Supported systems
  forAllSystems = inputs.nixpkgs.lib.genAttrs [
    "aarch64-linux"
    "i686-linux"
    "x86_64-linux"
    "aarch64-darwin"
    "x86_64-darwin"
  ];
}

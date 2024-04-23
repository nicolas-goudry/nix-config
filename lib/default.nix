{ inputs, outputs, stateVersion, ... }:

{
  # Supported systems
  forAllSystems = inputs.nixpkgs.lib.genAttrs [
    "aarch64-linux"
    "i686-linux"
    "x86_64-linux"
    "aarch64-darwin"
    "x86_64-darwin"
  ];

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
      modules = [ ../home ];
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
          isISO = builtins.substring 0 4 hostname == "iso-";
          cd-dvd =
            if (desktop == null) then
              "${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal-new-kernel-no-zfs.nix"
            else
              "${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-graphical-base.nix";
        in
        # Common host configuration merged with ISO installer if needed
        [ ../hosts ] ++ (inputs.nixpkgs.lib.optional isISO cd-dvd);
    };

  # Helper to wrap package with NixGL (https://github.com/nix-community/nixGL)
  # Source: https://github.com/Smona/nixpkgs/blob/f3d21833495edd036c245a0c4899e28e94c08362/applications/nixGL.nix#L4
  wrapNixGL = { pkg, platform ? "x86_64-linux" }: (pkg.overrideAttrs (prev: {
    name = "nixGL-${pkg.name}";

    buildCommand = ''
      set -eo pipefail

      ${inputs.nixpkgs.lib.concatStringsSep "\n" (map (outputName: ''
        echo "Copying output ${outputName}"
        set -x
        cp -rs --no-preserve=mode "${pkg.${outputName}}" "''$${outputName}"
        set +x
      '') (prev.outputs or [ "out" ]))}

      rm -rf $out/bin/*
      shopt -s nullglob # Prevent loop from running if no files
      for file in ${pkg.out}/bin/*; do
        echo "#!${inputs.nixpkgs.legacyPackages.${platform}.bash}/bin/bash" > "$out/bin/$(basename $file)"
        echo "exec -a \"\$0\" ${inputs.nixgl.packages.${platform}.nixGLIntel}/bin/nixGLIntel $file \"\$@\"" >> "$out/bin/$(basename $file)"
        chmod +x "$out/bin/$(basename $file)"
      done
      shopt -u nullglob # Revert nullglob back to its normal default state
    '';
  }));
}

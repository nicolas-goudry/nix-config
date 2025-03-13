{
  inputs,
  ...
}:

{
  # Helper to wrap package with NixGL (https://github.com/nix-community/nixGL)
  # Source: https://github.com/Smona/nixpkgs/blob/f3d21833495edd036c245a0c4899e28e94c08362/applications/nixGL.nix#L4
  wrapNixGL =
    {
      pkg,
      platform ? "x86_64-linux",
    }:
    (pkg.overrideAttrs (prev: {
      name = "nixGL-${pkg.name}";

      buildCommand = ''
        set -eo pipefail

        ${inputs.nixpkgs.lib.concatStringsSep "\n" (
          map (outputName: ''
            echo "Copying output ${outputName}"
            set -x
            cp -rs --no-preserve=mode "${pkg.${outputName}}" "''$${outputName}"
            set +x
          '') (prev.outputs or [ "out" ])
        )}

        rm -rf $out/bin/*
        shopt -s nullglob # Prevent loop from running if no files
        for file in ${pkg.out}/bin/*; do
          echo "#!${inputs.nixpkgs.legacyPackages.${platform}.bash}/bin/bash" > "$out/bin/$(basename $file)"
          echo "exec -a \"\$0\" ${
            inputs.nixgl.packages.${platform}.nixGLIntel
          }/bin/nixGLIntel $file \"\$@\"" >> "$out/bin/$(basename $file)"
          chmod +x "$out/bin/$(basename $file)"
        done
        shopt -u nullglob # Revert nullglob back to its normal default state
      '';
    }));
}

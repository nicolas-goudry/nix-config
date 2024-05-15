{ inputs, ... }:

{
  # Custom packages from the 'pkgs' directory
  additions = final: _prev:
    import ../pkgs {
      # Needed by install-system script
      inherit (inputs.disko.packages.${_prev.system}) disko;
      inherit (final) unstable;

      pkgs = final;

      nixvim = {
        lib = inputs.nixvim.lib.${_prev.system};
        nixvim = inputs.nixvim.legacyPackages.${_prev.system};
      };
    };

  # Change versions, add patches, set compilation flags, etc...
  # https://nixos.wiki/wiki/Overlays
  # deadnix: skip
  modifications = _final: _prev: {
    # example = prev.example.overrideAttrs (oldAttrs: rec {
    # ...
    # });
  };

  # Unstable nixpkgs set through 'pkgs.unstable'
  unstable-packages = final: _prev: {
    unstable = import inputs.nixpkgs-unstable {
      inherit (final) system;
      config.allowUnfree = true;
    };
  };
}

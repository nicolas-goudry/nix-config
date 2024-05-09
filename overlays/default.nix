{ inputs, ... }:

{
  # Custom packages from the 'pkgs' directory
  additions = final: _prev:
    let
      disko = inputs.disko.packages.${_prev.system};
    in
    import ../pkgs {
      # Needed by install-system script
      inherit (disko) disko;

      nixvim = inputs.nixvim.legacyPackages.${_prev.system};
      pkgs = final;
      inherit (final) unstable;
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

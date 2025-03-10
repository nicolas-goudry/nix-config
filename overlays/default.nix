{ inputs, ... }:

{
  # Custom packages from the 'pkgs' directory
  additions = final: _prev:
    import ../pkgs
      {
        # Needed by install-system script
        inherit (inputs.disko.packages.${_prev.system}) disko;

        pkgs = final;
      } // {
      nixvim = inputs.nixvim-config.packages.${_prev.system}.default;
      nixvim-lite = inputs.nixvim-config.packages.${_prev.system}.lite;
    };

  # Change versions, add patches, set compilation flags, etc...
  # https://wiki.nixos.org/wiki/Overlays
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

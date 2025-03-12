{ inputs, ... }@args:

let
  generators = import ./generators.nix args;
  nixgl = import ./nixgl.nix args;
in
{
  inherit (generators)
    mkHome
    mkHost
    mkUserSecrets
    ;
  inherit (nixgl)
    wrapNixGL
    ;

  # Supported systems
  forAllSystems = inputs.nixpkgs.lib.genAttrs [
    "aarch64-linux"
    "i686-linux"
    "x86_64-linux"
    "aarch64-darwin"
    "x86_64-darwin"
  ];
}

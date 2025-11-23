{ inputs, ... }@args:

let
  generators = import ./generators.nix args;
  nixgl = import ./wrap-nixgl.nix args;
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
}

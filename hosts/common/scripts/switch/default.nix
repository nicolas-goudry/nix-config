{ pkgs, ... }:

let
  name = builtins.baseNameOf (builtins.toString ./.);
  shellApplication = pkgs.writeShellApplication {
    inherit name;

    text = builtins.readFile ./${name}.sh;

    runtimeInputs = with pkgs; [
      coreutils
      gnused
      unixtools.column
    ];
  };
in
{
  environment.systemPackages = [ shellApplication ];
}

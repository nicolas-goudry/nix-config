{ pkgs, ... }:

let
  name = builtins.baseNameOf (builtins.toString ./.);
  shellApplication = pkgs.writeShellApplication {
    inherit name;

    text = builtins.readFile ./script.sh;

    runtimeInputs = with pkgs; [
      bc
      coreutils
      findutils
      gnused
      nix-output-monitor
      unixtools.column
    ];
  };
in
{
  environment.systemPackages = [ shellApplication ];
}

{ pkgs, ... }:

let
  name = builtins.baseNameOf (builtins.toString ./.);
  shellApplication = pkgs.writeShellApplication {
    inherit name;

    text = builtins.readFile ./${name}.sh;

    runtimeInputs = with pkgs; [
      bc
      coreutils
      findutils
      gnused
      nix-output-monitor
    ];
  };
in
{
  environment.systemPackages = [ shellApplication ];
}

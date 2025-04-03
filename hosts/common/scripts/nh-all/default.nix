{ pkgs, ... }:

let
  name = builtins.baseNameOf (builtins.toString ./.);
  shellApplication = pkgs.writeShellApplication {
    inherit name;

    text = builtins.readFile ./script.sh;

    runtimeInputs = with pkgs; [
      coreutils
      gnused
      unixtools.column
    ];
  };
  build-all = pkgs.writeScriptBin "build-all" ''nh-all build'';
  switch-all = pkgs.writeScriptBin "switch-all" ''nh-all switch'';
in
{
  environment.systemPackages = [
    shellApplication
    build-all
    switch-all
  ];
}

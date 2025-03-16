{ pkgs, ... }:

let
  name = builtins.baseNameOf (builtins.toString ./.);
  shellApplication = pkgs.writeShellApplication {
    inherit name;

    text = builtins.readFile ./${name}.sh;

    runtimeInputs = with pkgs; [
      bc
      coreutils
      gnused
      nh
      unixtools.column
    ];
  };
  build-home = pkgs.writeScriptBin "build-home" ''nh-home build'';
  switch-home = pkgs.writeScriptBin "switch-home" ''nh-home switch'';
in
{
  home.packages = [
    shellApplication
    build-home
    switch-home
  ];
}

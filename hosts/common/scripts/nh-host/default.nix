{ pkgs, ... }:

let
  name = builtins.baseNameOf (builtins.toString ./.);
  shellApplication = pkgs.writeShellApplication {
    inherit name;

    text = builtins.readFile ./script.sh;

    runtimeInputs = with pkgs; [
      bc
      coreutils
      gnused
      nh
      unixtools.column
    ];
  };
  build-host = pkgs.writeScriptBin "build-host" ''nh-host build'';
  switch-host = pkgs.writeScriptBin "switch-host" ''nh-host switch'';
in
{
  environment.systemPackages = [
    shellApplication
    build-host
    switch-host
  ];
}

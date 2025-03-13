{
  inputs,
  isISO,
  lib,
  platform,
  pkgs,
  ...
}:

let
  name = builtins.baseNameOf (builtins.toString ./.);
  shellApplication = pkgs.writeShellApplication {
    inherit name;

    text = builtins.readFile ./${name}.sh;

    runtimeInputs = with pkgs; [
      inputs.disko.packages.${platform}.default
      coreutils
      findutils
      git
      gnugrep
      gnupg
      gnused
      jq
      keyutils
      nixos-install-tools
      openssh
      rsync
      sops
      ssh-to-age
      util-linux
      yq
    ];
  };
in
{
  environment.systemPackages = lib.optionals isISO [ shellApplication ];
}

{ pkgs }:

{
  decrypt = import ./decrypt.nix { inherit pkgs; };
  encrypt = import ./encrypt.nix { inherit pkgs; };
  login = import ./login.nix { inherit pkgs; };
}

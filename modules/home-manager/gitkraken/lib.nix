{ config, lib }:

with lib;

let
  cfg = config.programs.gitkraken;
in
{
  # Function to get the value of an attribute in the given 'profile' at path 'attrPath' or fallback to "default" profile (top-level option)
  # If the attribute is found but null, fallback to "default" profile too
  fromProfileOrDefault = profile: attrPath:
    let
      resolved = attrByPath attrPath (getAttrFromPath attrPath cfg) profile;
    in
    if ((resolved == null) || resolved == "") then getAttrFromPath attrPath cfg else resolved;

  # Function to generate a fake UUID string from a SHA512 hash of a seed string
  # Generates a map with the first 32 characters of the hash splitted in groups of different size
  # and concatenate them in a string, each group separated by dashes
  generateFakeUuid = seed: concatStringsSep "-" (
    builtins.foldl'
      (acc: elem: acc ++ singleton (substring (elemAt elem 0) (elemAt elem 1) (builtins.hashString "sha512" seed)))
      [ ]
      [ [ 0 8 ] [ 8 4 ] [ 12 4 ] [ 16 4 ] [ 20 12 ] ]
  );
}

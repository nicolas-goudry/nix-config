{ nixvim, unstable }:

# Workaround to use nixvim with a flake not following unstable
# See https://github.com/nix-community/nixvim/issues/1377
nixvim.makeNixvimWithModule {
  extraSpecialArgs = { pkgs = unstable; };
  module = ./nixvim.nix;
  pkgs = unstable;
}

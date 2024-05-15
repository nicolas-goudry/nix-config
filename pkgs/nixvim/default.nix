{ nixvim, unstable }:

# Workaround to use nixvim with a flake not following unstable
# See https://github.com/nix-community/nixvim/issues/1377
nixvim.nixvim.makeNixvimWithModule {
  extraSpecialArgs = { pkgs = unstable; libn = nixvim.lib; };
  module = ./nixvim.nix;
  pkgs = unstable;
}

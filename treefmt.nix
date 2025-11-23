{
  projectRootFile = "flake.nix";
  programs.nixfmt.enable = true;
  programs.shellcheck.enable = true;

  programs.prettier = {
    enable = true;

    excludes = [
      "**/secrets.yaml"
    ];
  };
}

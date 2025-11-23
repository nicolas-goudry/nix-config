{ stdenvNoCC, lib }:

stdenvNoCC.mkDerivation {
  pname = "omz-custom-plugins";
  version = "custom";

  src = ./.;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/plugins
    find . -maxdepth 1 -type d -exec cp -R {} $out/plugins \;

    runHook postInstall
  '';

  meta = with lib; {
    description = "Custom plugins and overrides for oh-my-zsh";
    maintainers = [ maintainers.nicolas-goudry ];
  };
}

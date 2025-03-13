{
  stdenvNoCC,
  lib,
  fetchFromGitHub,
}:

stdenvNoCC.mkDerivation {
  pname = "catppuccin-gitkraken";
  version = "unstable";

  src = fetchFromGitHub {
    owner = "catppuccin";
    repo = "gitkraken";
    rev = "v1.1.0";
    hash = lib.fakeHash;
  };

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp src/catppuccin-*.jsonc $out

    runHook postInstall
  '';

  meta = with lib; {
    description = "Soothing pastel theme for GitKraken";
    homepage = "https://github.com/davi19/gitkraken";
    license = licenses.mit;
    maintainers = [ maintainers.nicolas-goudry ];
  };
}

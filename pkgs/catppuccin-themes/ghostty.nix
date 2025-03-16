{
  stdenvNoCC,
  lib,
  fetchFromGitHub,
}:

stdenvNoCC.mkDerivation {
  pname = "catppuccin-ghostty";
  version = "unstable";

  src = fetchFromGitHub {
    owner = "catppuccin";
    repo = "ghostty";
    rev = "9e38fc2b4e76d4ed5ff9edc5ac9e4081c7ce6ba6";
    hash = "sha256-df4m2WUotT2yFPyJKEq46Eix/2C/N05q8aFrVQeH1sA=";
  };

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp themes/catppuccin-*.conf $out

    runHook postInstall
  '';

  meta = with lib; {
    description = "Soothing pastel theme for Ghostty";
    homepage = "https://github.com/catppuccin/ghostty";
    license = licenses.mit;
    maintainers = [ maintainers.nicolas-goudry ];
  };
}

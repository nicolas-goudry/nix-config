{ stdenvNoCC
, lib
, fetchFromGitHub
}:

stdenvNoCC.mkDerivation {
  pname = "catppuccin-gitkraken";
  version = "unstable";

  # TODO: use official repository once https://github.com/catppuccin/catppuccin/issues/2170 gets merged
  src = fetchFromGitHub {
    owner = "davi19";
    repo = "gitkraken";
    rev = "c4077687174c85e7196c460b307a578a2b022888";
    hash = "sha256-4bmrgI8NI7mC1PTssGtucPNJAAZimQeyMjffrY4Dme0=";
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

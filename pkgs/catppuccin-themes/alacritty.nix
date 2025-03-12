{ stdenvNoCC
, lib
, fetchFromGitHub
}:

stdenvNoCC.mkDerivation {
  pname = "catppuccin-alacritty";
  version = "unstable";

  src = fetchFromGitHub {
    owner = "catppuccin";
    repo = "alacritty";
    rev = "94800165c13998b600a9da9d29c330de9f28618e";
    hash = "sha256-Pi1Hicv3wPALGgqurdTzXEzJNx7vVh+8B9tlqhRpR2Y=";
  };

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp catppuccin-*.toml $out

    runHook postInstall
  '';

  meta = with lib; {
    description = "Soothing pastel theme for Alacritty";
    homepage = "https://github.com/catppuccin/alacritty";
    license = licenses.mit;
    platforms = platforms.unix;
    maintainers = [ maintainers.nicolas-goudry ];
  };
}

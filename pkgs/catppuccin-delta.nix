{ stdenvNoCC
, lib
, fetchFromGitHub
}:

stdenvNoCC.mkDerivation {
  pname = "catppuccin-delta";
  version = "unstable";

  src = fetchFromGitHub {
    owner = "catppuccin";
    repo = "delta";
    rev = "765eb17d0268bf07c20ca439771153f8bc79444f";
    hash = "sha256-GA0n9obZlD0Y2rAbGMjcdJ5I0ij1NEPBFC7rv7J49QI=";
  };

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp catppuccin.gitconfig $out

    runHook postInstall
  '';

  meta = with lib; {
    description = "Soothing pastel theme for delta";
    homepage = "https://github.com/catppuccin/delta";
    license = licenses.mit;
    platforms = platforms.unix;
    maintainers = [ maintainers.nicolas-goudry ];
  };
}

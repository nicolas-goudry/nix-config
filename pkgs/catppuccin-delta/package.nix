{
  stdenvNoCC,
  lib,
  fetchFromGitHub,
}:

stdenvNoCC.mkDerivation {
  pname = "catppuccin-delta";
  version = "unstable";

  src = fetchFromGitHub {
    owner = "catppuccin";
    repo = "delta";
    rev = "e9e21cffd98787f1b59e6f6e42db599f9b8ab399";
    hash = "sha256-04po0A7bVMsmYdJcKL6oL39RlMLij1lRKvWl5AUXJ7Q=";
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

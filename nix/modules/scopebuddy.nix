{ lib, stdenv, fetchFromGitHub, makeWrapper, gamescope, jq }:

stdenv.mkDerivation rec {
  pname = "scopebuddy";
  version = "1.2.5";

  src = fetchFromGitHub {
    owner = "HikariKnight";
    repo = "ScopeBuddy";
    rev = "eeff77a8eea05d6cf336c4650a396718dc6b30c2";
    hash = "sha256-e3+/IKB9w50snYNa+85TZ0T2e4FmRmnmJK3NwGGunbc=";
  };

  nativeBuildInputs = [ makeWrapper ];

  buildInputs = [ gamescope jq ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    cp bin/scopebuddy $out/bin/scopebuddy
    cp bin/scb $out/bin/scb

    chmod +x $out/bin/scopebuddy
    chmod +x $out/bin/scb

    wrapProgram $out/bin/scopebuddy \
      --prefix PATH : ${lib.makeBinPath [ gamescope jq ]}

    runHook postInstall
  '';

  meta = with lib; {
    description = "Helper script for launching games with gamescope";
    homepage = "https://github.com/HikariKnight/ScopeBuddy";
    license = licenses.gpl3Only;
    platforms = platforms.linux;
    maintainers = [ ];
  };
}

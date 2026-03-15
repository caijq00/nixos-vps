{ lib, stdenv, fetchurl, dpkg }:

stdenv.mkDerivation rec {
  pname = "emby-server";
  version = "4.9.3.0";

  src = fetchurl {
    url = "https://github.com/MediaBrowser/Emby.Releases/releases/download/${version}/emby-server-deb_${version}_amd64.deb";
    sha256 = "sha256-Tt+P6BnYm5efSuu6sF9Zi7q/RLh/Rg+zIi5pEqiwpzM=";
  };

  nativeBuildInputs = [ dpkg ];

  unpackPhase = "true";

  installPhase = ''
    dpkg-deb -x $src $out
    mkdir -p $out/bin
    ln -s $out/opt/emby-server/bin/emby-server $out/bin/emby-server
  '';

  meta = with lib; {
    description = "Emby Server";
    homepage = "https://emby.media";
    license = licenses.unfree;
    platforms = [ "x86_64-linux" ];
  };
}

{
  pkgs ? import <nixpkgs> { },
  lib,
  ...
}:

let
  openpace = pkgs.stdenv.mkDerivation rec {
    pname = "openpace";
    version = "1.1.3";

    src = pkgs.fetchFromGitHub {
      owner = "frankmorgner";
      repo = "openpace";
      tag = version;
      hash = "sha256-KsgCTHvbqxNOcf9HWgXGxagpIjHEcQ5Kryjq71F8XRk=";
    };

    nativeBuildInputs = with pkgs; [
      autoreconfHook
      pkg-config
      help2man
      gengetopt
    ];

    buildInputs = with pkgs; [ openssl ];

    preConfigure = ''
      autoreconf --verbose --install
    '';

    meta = with pkgs; {
      description = "Cryptographic library for EAC version 2";
      homepage = "https://github.com/frankmorgner/openpace";
      license = lib.licenses.gpl3Plus;
      platforms = lib.platforms.unix;
      maintainers = with lib.maintainers; [ vaavaav ];
    };
  };

  xercesc_3_2 = pkgs.stdenv.mkDerivation rec {
    pname = "xerces-c";
    version = "3.2.3";

    src = pkgs.fetchurl {
      url = "mirror://apache/xerces/c/3/sources/${pname}-${version}.tar.gz";
      hash = "sha256-+5b8SbH7iS0eZOU6atqKzPbw5tMM4JN5Vuxo05vXLH4=";
    };

    nativeBuildInputs = [ pkgs.pkg-config ];
    configureFlags = [ "--disable-static" ];

    meta = {
      description = "Validating XML parser written in a portable subset of C++";
      homepage = "https://xerces.apache.org/xerces-c/";
      license = lib.licenses.asl20;
      platforms = lib.platforms.unix;
    };
  };

in
pkgs.stdenv.mkDerivation rec {
  name = "autenticacao-gov-pt";
  version = "3.13.3";
  src = pkgs.fetchurl {
    url = "https://github.com/amagovpt/autenticacao.gov/releases/download/v${version}/pteid-mw-${version}.flatpak";
    hash = "sha256-kUSUcX3/rPENdyd6ABeqADqK4CcSltwsdnmcgWzw8Fc=";
  };

  dontConfigure = true;
  dontBuild = true;
  dontWrapQtApps = true;

  nativeBuildInputs = with pkgs; [
    makeWrapper
    copyDesktopItems
    autoPatchelfHook
    flatpak
    ostree
    patchelf
  ];

  buildInputs = with pkgs; [
    bash
    ccid
    cjson
    curl
    doxygen
    libGL
    libgcc
    libsForQt5.poppler
    libsForQt5.qt5.wrapQtAppsHook
    libzip
    openjpeg
    openpace
    openssl
    pcsclite
    proot
    qt5.qtbase
    qt5.qtgraphicaleffects
    qt5.qtquickcontrols
    qt5.qtquickcontrols2
    qt5.qttools
    xercesc_3_2
    xml-security-c
  ];

  unpackPhase = ''
    ostree init --repo=pteid --mode=archive-z2
    ostree static-delta apply-offline --repo=pteid ${src}
    ostree checkout --repo=pteid -U $(echo pteid/objects/*/*.commit | sed -E "s/.*\/([^\/]+)\/([^\/]+)\.commit$/\1\2/") pteid_out
  '';

  desktopItems = [
    (pkgs.makeDesktopItem {
      name = name;
      exec = name;
      desktopName = "Autenticação.gov";
      genericName = "Portuguese eID Data";
      comment = "Middleware for Electronic Identification in Portugal";
      icon = "pt.gov.autenticacao";
      terminal = false;
      startupNotify = true;
      categories = [ "Office" ];
    })
  ];

  preInstall = ''
    mkdir -p $out/share/applications $out/app/{lib,share} 
    cp -r pteid_out/files/bin $out/app
    cp -r pteid_out/files/lib/lib{pteid,CMD}* $out/app/lib/
    cp -r pteid_out/files/share/certs $out/app/share
    cp -r pteid_out/files/share/icons $out/share
  '';

  postInstall = ''
    makeWrapper "${pkgs.proot}/bin/proot" "$out/bin/${name}" \
      --add-flags "-b" \
      --add-flags "$out/app:/app" \
      --add-flags "$out/app/bin/eidguiV2" \
      --argv0 "$out/bin/eidguiV2"
  '';

  preFixup = ''
    find $out/app/lib -type f -name '*.so*' | while read lib; do
      patchelf --replace-needed libxml-security-c.so.20 libxml-security-c.so.30 "$lib"
    done
    wrapQtApp $out/app/bin/eidguiV2
    autoPatchelf $out/app
  '';

  meta = {
    description = "Middleware for Electronic Identification in Portugal (with pre compiled binaries by AMA)";
    homepage = "https://www.autenticacao.gov.pt/";
    license = lib.licenses.eupl12;
    platforms = lib.platforms.unix;
    maintainers = with lib.maintainers; [ vaavaav ];
  };
}

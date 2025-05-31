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
in
pkgs.stdenv.mkDerivation rec {
  name = "autenticacao-gov-pt";
  version = "3.13.0";
  src = pkgs.fetchurl {
    url = "https://github.com/amagovpt/autenticacao.gov/releases/download/v${version}/pteid-mw-${version}.flatpak";
    hash = "sha256-lKZFdbvuEX9eYC8ABvFY2yVtvEywatwZ8TuZn2c2Jb0=";
  };

  dontConfigure = true;
  dontBuild = true;
  dontWrapQtApps = true;

  nativeBuildInputs = with pkgs; [
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
    xercesc
    xml-security-c
  ];

  desktopItem = pkgs.makeDesktopItem {
    name = name;
    exec = name;
    desktopName = "Autenticação.gov";
    genericName = "Portuguese eID Data";
    comment = "Middleware for Electronic Identification in Portugal";
    icon = "pt.gov.autenticacao";
    terminal = false;
    startupNotify = true;
    categories = [ "Office" ];
  };

  unpackPhase = ''
    # Initialize the ostree repository
    ostree init --repo=pteid --mode=archive-z2
    # Import the flatpak
    ostree static-delta apply-offline --repo=pteid ${src} 
    # Go to the latest commit (theoretically, the only one)
    ostree checkout --repo=pteid -U $(echo pteid/objects/*/*.commit | sed -E "s/.*\/([^\/]+)\/([^\/]+)\.commit$/\1\2/") pteid_out
  '';

  installPhase = ''
    mkdir -p $out/app/lib $out/app/share $out/share $out/bin
    cp -r pteid_out/files/bin $out/app
    cp -r pteid_out/files/lib/lib{pteid,CMD}* $out/app/lib/
    cp -r pteid_out/files/share/certs $out/app/share
    cp -r pteid_out/files/share/icons $out/share
    cp -r ${desktopItem}/share/applications $out/share

    echo "#!/bin/env bash
    ${pkgs.proot}/bin/proot -b $out/app:/app $out/app/bin/eidguiV2 \$@" > $out/bin/${name}
    chmod +x $out/bin/${name}
  '';

  preFixup = ''
    # libxml-security-c.so.20 is deprecated
      find $out/app/lib -type f -name '*.so*' | while read lib; do
       patchelf --replace-needed libxml-security-c.so.20 libxml-security-c.so "$lib"
       patchelf --replace-needed libxerces-c-3.2.so libxerces-c.so "$lib"
       patchelf --replace-needed libzip.so.5 libzip.so "$lib"
     done

    # Let the Qt apps know where to find plugins
     wrapQtApp $out/app/bin/eidguiV2 

     # Auto patch all libraries
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

{ pkgs ? import <nixpkgs> {} }:

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
  name = "autenticacao-gov-bin";
  version = "3.13.0";
  src = pkgs.fetchurl {
    url = "https://github.com/amagovpt/autenticacao.gov/releases/download/v${version}/pteid-mw-${version}.flatpak";
    sha256 = "94a64575bbee117f5e602f0006f158db256dbc4cb06adc19f13b999f673625bd";
  };

  dontConfigure = true;
  dontBuild = true;

  nativeBuildInputs = with pkgs; [
    bash
    binutils
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
    copyDesktopItems
  ];

  buildInputs = with pkgs; [
    autoPatchelfHook
    bash
    flatpak
    git
    ostree
    patchelf
  ];

  unpackPhase = ''
    mkdir -p pteid
    ostree init --repo=pteid --mode=archive-z2
    ostree static-delta apply-offline --repo=pteid ${src} 
    commit_file=$(echo pteid/objects/*/*.commit | cut -d/ -f3- --output-delimiter="" | tr -d '\0')
    commit_basename=$(basename "$commit_file" .commit)
    ostree checkout --repo=pteid -U "$commit_basename" pteid_out
    mkdir -p $out $out/lib $out/share
    cp -r pteid_out/files/bin $out
    cp -r pteid_out/files/lib/libpteid* $out/lib/
    cp -r pteid_out/files/lib/libCMD* $out/lib/
    cp -r pteid_out/files/share/certs $out/share
    cp -r pteid_out/files/share/icons $out/share
  '';

  desktopItem = pkgs.makeDesktopItem {
            name = "autenticacao-gov-bin";
            exec = name;
            desktopName = "Autenticação.gov";
            genericName = "Portuguese eID Data";
            comment = "See and change information on your Portuguese eID Card";
            icon = "pt.gov.autenticacao";
            terminal = false;
            startupNotify = true;
            categories = [ "Office" ];
          };

  installPhase = ''
    cp -r ${desktopItem}/share/applications $out/share
    echo "#!/bin/env bash
    ${pkgs.proot}/bin/proot -b $out:/app $out/bin/eidguiV2 \$@" > $out/bin/${name}
    chmod +x $out/bin/${name}
  '';

  preFixup = ''
    find $out/lib -type f -name '*.so*' | while read lib; do
       patchelf --replace-needed libxml-security-c.so.20 libxml-security-c.so.30 "$lib"
     done

     # Auto patch all libraries
     autoPatchelf $out
  '';


  meta = with pkgs; {
    description = "Official Middleware for Electronic Identification in Portugal - Citizen Card, Digital Mobile Key and Certification System for Professional Attributes";
    homepage = "https://www.autenticacao.gov.pt/";
    license = lib.licenses.eupl12;
    platforms = lib.platforms.unix;
    maintainers = with lib.maintainers; [ vaavaav ];
    mainProgram = name;
  };

}

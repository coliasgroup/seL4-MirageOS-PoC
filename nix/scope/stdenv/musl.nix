{ lib, stdenv, fetchFromGitHub }:

stdenv.mkDerivation rec {
  name = "musl";

  src = fetchFromGitHub {
    owner = "seL4";
    repo = "musllibc";
    rev = "3d6b939e8f05cb1d2a1a8c8166609bf2e652e975";
    hash = "sha256-u+5mKtuL0bkObxnhb78ARNf9iaYwVP3q/0YcCwC5YkQ=";
  };

  hardeningDisable = [ "all" ]; # TODO

  NIX_CFLAGS_COMPILE = [
    "-fdebug-prefix-map=.=${src}"
  ];

  dontDisableStatic = true;
  dontFixup = true;

  configureFlags = [
    "--enable-debug"
    "--enable-warnings"
    "--disable-shared"
    "--enable-static"
    "--disable-optimize"
    "--disable-visibility" # HACK
  ];

  postConfigure = ''
    sed -i 's/^ARCH = \(.*\)/ARCH = \1_sel4/' config.mak
  '';

  makeFlags = [
    "-f" "Makefile.muslc"
  ];
}

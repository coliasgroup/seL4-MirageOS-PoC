{ stdenv, callPackage
, musl
}:

let
  mkStdenv = libc: stdenv.override (drv: {
    cc = drv.cc.override {
      extraPackages = [];
      inherit libc;
      bintools = stdenv.cc.bintools.override {
        inherit libc;
        noLibc = false;
      };
      noLibc = false;
    };
    allowedRequisites = null;
  });

in {
  inherit mkStdenv;

  stdenvMirage = mkStdenv (callPackage ./libc-wrappers/mirage.nix {});
}

{ lib
, llvmPackages
, seL4Modifications
, crateUtils
, stdenvMirage
, icecap-ocaml-runtime
, mkTaskHere
}:

{ crate, targetTriple, mirageLibrary }:
  
mkTaskHere rec {
  stdenv = stdenvMirage;

  rootCrate = crate;

  inherit targetTriple;

  layers = [
    crateUtils.defaultIntermediateLayer
    {
      crates = [
        "sel4-microkit"
      ];
      modifications = seL4Modifications;
    }
  ];

  commonModifications = {
    modifyConfig = lib.flip lib.recursiveUpdate {
      target."cfg(any(unique_hack_mirage, target_os = \"none\"))".rustflags = [
        "-C" "linker=${stdenv.cc.targetPrefix}ld.lld"
      ] ++ lib.concatMap (x: [ "-C" "link-arg=-l${x}" ]) [
        "c" "sel4asmrun" "glue" "mirage"
      ];
    };
  };

  lastLayerModifications = {
    modifyDerivation = drv: drv.overrideAttrs (self: super: {
      nativeBuildInputs = (super.nativeBuildInputs or []) ++ [
        llvmPackages.bintoolsNoLibc
      ];
      buildInputs = (super.buildInputs or []) ++ [
        stdenv.cc.libc
        icecap-ocaml-runtime
        mirageLibrary
      ];
      passthru = (super.passthru or {}) // {
        inherit mirageLibrary;
      };
    });
  };
}

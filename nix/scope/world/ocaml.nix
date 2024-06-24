{ lib, stdenv
, musl
, defaultRustTargetTriple
, icecap-ocaml-runtime
, stdenvMirage
, libsel4
, llvmPackages
, mkTaskHere
, seL4Modifications
, crateUtils
}:

{
  mkMirageBinary = { crate, targetTriple, mirageLibrary }:
  
  let
    rustTargetNameForEnv = lib.toUpper (lib.replaceStrings ["-"] ["_"] targetTriple.name);
  in

  mkTaskHere {
    stdenv = stdenvMirage;

    rootCrate = crate;

    layers = [
      crateUtils.defaultIntermediateLayer
      {
        crates = [
          "sel4-microkit"
        ];
        modifications = seL4Modifications;
      }
    ];

    inherit targetTriple;

    commonModifications = {
      modifyDerivation = drv: drv.overrideAttrs (self: super: {
        # HACK
        # NOTE
        #   Affects fingerprints, so causes last layer to build too much.
        # TODO
        #   If must use this hack, use extraLastLayerCargoConfig instead, which is
        #   more composable. Env vars override instead of composing.
        "CARGO_TARGET_${rustTargetNameForEnv}_RUSTFLAGS" = lib.concatMap (x: [ "-C" "link-arg=-l${x}" ]) [
          "glue" "sel4asmrun" "mirage" "sel4asmrun" "glue" "c" "gcc"
        ] ++ [
          "-C" "linker=${stdenv.cc.targetPrefix}ld.lld"
          # TODO shouldn't be necessary
          "-C" (let cc = stdenv.cc.cc; in "link-arg=-L${cc}/lib/gcc/${cc.targetConfig}/${cc.version}")
        ];
      });
    };

    lastLayerModifications = {
      modifyDerivation = drv: drv.overrideAttrs (self: super: {
        buildInputs = (super.buildInputs or []) ++ [
          musl
          # stdenvMirage.cc.libc # HACK
          # libsel4
          icecap-ocaml-runtime
          mirageLibrary
        ];
        nativeBuildInputs = (super.nativeBuildInputs or []) ++ [
          llvmPackages.bintoolsNoLibc
        ];
        passthru = (super.passthru or {}) // {
          inherit crate mirageLibrary;
        };
      });
    };
  };
}

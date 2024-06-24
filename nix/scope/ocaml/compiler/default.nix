{ lib, stdenv, buildPlatform, hostPlatform, targetPlatform
, runCommand, removeReferencesTo
, ocamlSrc, ocamlVersion, ocamlBuildBuild, targetCC
}:

let

  name = "ocaml";
  version = ocamlVersion;
  src = ocamlSrc;

  ocamlView = runCommand "ocaml-view" {} ''
    mkdir -p $out/bin
    ln -s ${ocamlBuildBuild}/bin/ocamlrun* $out/bin
    ln -s ${ocamlBuildBuild}/bin/ocamlyacc $out/bin
  '';

  notCross = stdenv.mkDerivation rec {

    inherit name version src;

    prefixKey = "-prefix ";

    buildFlags = [ "world" "bootstrap" "world.opt" ];

    installTargets = [ "install" "installopt" ];

    postInstall = ''
      mkdir -p $out/include
      ln -sv $out/lib/ocaml/caml $out/include/caml
    '';

    # dontStrip = true;
    # dontFixup = true;

  };

  cross = stdenv.mkDerivation rec {

    inherit name version src;

    outputs = [ "out" "runtime" ];

    depsBuildBuild = [ ocamlView ];
    depsBuildTarget = [ targetCC ];
    nativeBuildInputs = [ removeReferencesTo ];

    # NIX_DEBUG = 1;

    postPatch = ''
      sed -i 's,^\([^+]*\)+.*$,\1,' VERSION # HACK
      sed -i 's,TOOLPREF=.*,TOOLPREF=${targetCC.targetPrefix},' configure
    '';

    configurePhase = ''
      ./configure \
        -host ${hostPlatform.config} \
        -target ${if targetPlatform.config == "aarch64-none-elf" then "aarch64-unknown-linux-gnu" else targetPlatform.config} \
        -no-ocamldoc \
        -no-ocamltest \
        -target-bindir $runtime/bin \
        -prefix $out
    '';
        # -verbose \

    # buildPhase = ''
    #   make world opt
    # '';
    #   # make world world.opt
    #   # make compilerlibs/ocamlcommon.cmxa compilerlibs/ocamlbytecomp.cmxa compilerlibs/ocamloptcomp.cmxa

    buildFlags = [
      "world" "world.opt"
    ];

    # TODO fix build-platform ocamlrun hack

    installPhase = ''
      make install installopt

      mkdir -p $runtime/bin
      mv $out/bin/ocamlrun* $runtime/bin
      mv $out/bin/ocamlyacc $runtime/bin
      remove-references-to -t $out $runtime/bin/*

      ln -s ${ocamlView}/bin/ocamlrun* $out/bin
      ln -s ${ocamlView}/bin/ocamlyacc $out/bin

      rm $out/bin/ocamlcmt
      rm $out/bin/*.opt

      for x in $(find $out/bin -type l -printf '%l\n' | sed -n 's/\.opt$//p'); do
        ln -sf $out/bin/$x.byte $out/bin/$x
      done

      mkdir -p $out/include
      ln -sv $out/lib/ocaml/caml $out/include/caml
    '';

    dontStrip = true; # TODO unecessary
    dontFixup = true;

  };

in
  if hostPlatform.config == targetPlatform.config then notCross else cross
  # if hostPlatform.config != targetPlatform.config then notCross else cross
  # notCross

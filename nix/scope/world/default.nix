{ lib
, mirage
, mkSeL4RustTargetTriple
, perl
, buildPackages
, globalPatchSection
}:

self: super:

let
  inherit (mirage)
    crates
    ocamlScope
    icecap-ocaml-runtime
    stdenvMirage
    musl
  ;

  inherit (self)
    callPackage
    mkTask
    microkit
    callPlatform
  ;

in rec {

  mkTaskHere = mkTask.override {
    inherit (mirage) defaultRustEnvironment buildCratesInLayers;
  };

  inherit (callPackage ./ocaml.nix {
    inherit icecap-ocaml-runtime stdenvMirage musl;
  }) mkMirageBinary;

  targetTriple = mkSeL4RustTargetTriple { microkit = true; };

  mirageLibrary = ocamlScope.callPackage ./mirage {};

  pds = {
    demo-mirage-unikernel = mkMirageBinary {
      crate = crates.demo-mirage-unikernel;
      inherit mirageLibrary;
      inherit targetTriple;
    };
    sp804-driver = mkTaskHere {
      rootCrate = crates.sp804-driver;
      release = true;
      inherit targetTriple;
    };
    virtio-net-driver = mkTaskHere {
      rootCrate = crates.virtio-net-driver;
      release = true;
      inherit targetTriple;
    };
  };

  demo = lib.fix (self: callPlatform {
    system = microkit.mkSystem {
      systemXML = ../../../demo.system;
      searchPath = [
        "${pds.demo-mirage-unikernel}/bin"
        "${pds.sp804-driver}/bin"
        "${pds.virtio-net-driver}/bin"
      ];
    };

    extraPlatformArgs = {
      extraQEMUArgs = [
        "-device" "virtio-net-device,netdev=netdev0"
        "-netdev" "user,id=netdev0,net=192.168.1.0/24,host=192.168.1.1,hostfwd=tcp::8080-192.168.1.2:8080"
      ];
    };

    inherit pds;

    # automate =
    #   let
    #     py = buildPackages.python3.withPackages (pkgs: [
    #       pkgs.pexpect
    #       pkgs.requests
    #     ]);
    #   in
    #     writeScript "automate" ''
    #       #!${buildPackages.runtimeShell}
    #       set -eu
    #       ${py}/bin/python3 ${./automate.py} ${self.simulate}
    #     '';
  });

}

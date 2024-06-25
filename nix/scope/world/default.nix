{ lib
, buildPackages
, perl
, globalPatchSection
, mkSeL4RustTargetTriple
, mirage
}:

let
  inherit (mirage)
    crates
    ocamlScope
    stdenvMirage
    icecap-ocaml-runtime
  ;
in

self: super: with self; {

  mkTaskHere = mkTask.override {
    inherit (mirage) defaultRustEnvironment buildCratesInLayers;
  };

  mkMirageBinary = callPackage ./ocaml.nix {
    inherit stdenvMirage icecap-ocaml-runtime;
  };

  mirageLibrary = ocamlScope.callPackage ./mirage {};

  demo = callPlatform rec {
    pds =
      let
        targetTriple = mkSeL4RustTargetTriple { microkit = true; };
      in {
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

    system = microkit.mkSystem {
      systemXML = ../../../demo.system;
      searchPath = map (x: "${x}/bin") [
        pds.demo-mirage-unikernel
        pds.sp804-driver
        pds.virtio-net-driver
      ];
    };

    extraPlatformArgs = {
      extraQEMUArgs = [
        "-device" "virtio-net-device,netdev=netdev0"
        "-netdev" "user,id=netdev0,net=192.168.1.0/24,host=192.168.1.1,hostfwd=tcp::8080-192.168.1.2:8080"
      ];
    };
  };

}

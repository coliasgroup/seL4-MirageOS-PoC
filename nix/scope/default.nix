{ lib, splicePackages
, this
, buildCratesInLayers
, vendorLockfile
}:

self: with self;

let

in {
  defaultRustEnvironment = this.defaultRustEnvironment.override {
    vendoredSuperLockfile = vendorLockfile { lockfile = ../../Cargo.lock; };
  };

  buildCratesInLayers = this.buildCratesInLayers.override {
    inherit defaultRustEnvironment;
  };

  crates = callPackage ./crates.nix {};

  inherit (callPackage ./stdenv {}) stdenvMirage;

  musl = callPackage ./stdenv/musl.nix {};

  ocamlScope =
    let
      superOtherSplices = otherSplices;
    in
    let
      otherSplices = with superOtherSplices; {
        selfBuildBuild = selfBuildBuild.ocamlScope;
        selfBuildHost = selfBuildHost.ocamlScope;
        selfBuildTarget = selfBuildTarget.ocamlScope;
        selfHostHost = selfHostHost.ocamlScope;
        selfTargetTarget = selfTargetTarget.ocamlScope or {};
      };
    in
      lib.makeScopeWithSplicing
        splicePackages
        newScope
        otherSplices
        (_: {})
        (_: {})
        (self: callPackage ./ocaml {} self // {
          __dontMashWhenSplicingChildren = true;
          inherit superOtherSplices otherSplices; # for convenience
        })
      ;

  inherit (ocamlScope) icecap-ocaml-runtime;
}

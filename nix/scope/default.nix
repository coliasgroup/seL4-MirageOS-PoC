{ lib, splicePackages
}:

self: with self;

let

in {
  inherit (callPackage ./stdenv {}) mkStdenv stdenvMirage;

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

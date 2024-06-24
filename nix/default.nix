{ base ? import ../rust-sel4 {} }:

let
  inherit (base) lib;

  baseWithOverrides = base.override (superArgs: selfBase:
    let
      concreteSuperArgs = superArgs selfBase;
    in
      concreteSuperArgs // {
        nixpkgsArgsFor = crossSystem:
          let
            superNixpkgsArgs = concreteSuperArgs.nixpkgsArgsFor crossSystem;
          in
            superNixpkgsArgs // {
              overlays = superNixpkgsArgs.overlays ++ [
                (import ./overlay)
              ];
            };
      }
  );

in
  lib.fix (self: {
    base = baseWithOverrides;
    inherit (baseWithOverrides) lib pkgs;
  } // import ./top-level self)

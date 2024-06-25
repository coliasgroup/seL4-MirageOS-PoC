{ base ? import ../rust-sel4 {} }:

let
  inherit (base) lib;

  baseWithOverrides = base.withOverlays [
    (import ./overlay)
  ];

in
  lib.fix (self: {
    base = baseWithOverrides;
  } // import ./top-level self)

self: with self;

let
in {
  inherit (base) lib pkgs worlds;

  inherit (pkgs.host.aarch64.none) this;

  inherit (this) mirage;

  world = worlds.aarch64.qemu-arm-virt.microkit;

  inherit (world) demo;

  inherit (demo) simulate;

  build = demo.links;

  pd = demo.pds.demo-mirage-unikernel;

  test =
    let
      inherit (pkgs.build) python3 writeScript runtimeShell;
      py = python3.withPackages (pkgs: [
        pkgs.pexpect
        pkgs.requests
      ]);
    in
      writeScript "test" ''
        #!${runtimeShell}
        set -eu

        ${py}/bin/python3 ${../../test.py} ${simulate}
      '';

  x = {
    x = scope.mirage.ocamlScope.otherSplices.selfBuildHost.ocaml;
  };
}



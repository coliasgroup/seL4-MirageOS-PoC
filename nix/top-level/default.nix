self: with self;

let
in {
  inherit (base) lib pkgs worlds;

  world = worlds.aarch64.qemu-arm-virt.microkit;

  demo = world.demo;

  build = demo.links;

  pd = demo.pds.demo-mirage-unikernel;

  inherit (demo) simulate;

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
}

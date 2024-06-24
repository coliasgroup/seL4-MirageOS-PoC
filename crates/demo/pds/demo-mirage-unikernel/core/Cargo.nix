{ mk, localCrates, serdeWith, versions, smoltcpWith }:

mk {
  package.name = "demo-mirage-unikernel-core";
  dependencies = with localCrates; {
    serde = serdeWith [ "alloc" "derive" ];
    serde_json = { version = versions.serde_json; default-features = false; features = [ "alloc" ]; };
    cortex-a = "8.1.1";
    tock-registers = {
      version = versions.tock-registers;
      default-features = false;
    };
    inherit (versions) log lock_api;

    smoltcp = smoltcpWith [
      "log"
    ];

    inherit (localCrates)
      sel4
      sel4-sync
      sel4-logging
      sel4-immediate-sync-once-cell
      sel4-microkit-message
      sel4-microkit-driver-adapters
      sel4-driver-interfaces
      sel4-shared-ring-buffer-bookkeeping
      sel4-bounce-buffer-allocator
      sel4-shared-ring-buffer
      sel4-shared-ring-buffer-smoltcp
      sel4-linux-syscall-types
      sel4-linux-syscall-musl
      sel4-mirage-core
    ;

    sel4-microkit = localCrates.sel4-microkit // { default-features = false; features = [ "alloc" ]; };
    sel4-externally-shared = localCrates.sel4-externally-shared // { features = [ "unstable" ]; };

  };
  build-dependencies = {
    cc = "1.0.76";
    glob = "0.3.0";
  };
}

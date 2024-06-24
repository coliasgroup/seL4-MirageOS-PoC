#
# Copyright 2023, Colias Group, LLC
#
# SPDX-License-Identifier: BSD-2-Clause
#

{ mk, localCrates, versions, serdeWith, smoltcpWith }:

mk {
  package.name = "demo-mirage-unikernel";

  dependencies = {
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
      demo-mirage-unikernel-core
    ;

    sel4-microkit = localCrates.sel4-microkit // { default-features = false; features = [ "alloc" ]; };
    sel4-externally-shared = localCrates.sel4-externally-shared // { features = [ "unstable" ]; };
  };
}

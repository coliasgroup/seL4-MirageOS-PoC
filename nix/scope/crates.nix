{ lib
, crateUtils
}:

let
  workspaceDir = ../..;
  workspaceManifestPath = workspaceDir + "/Cargo.toml";
  workspaceManifest = builtins.fromTOML (builtins.readFile workspaceManifestPath);
  workspaceMemberPaths = map (member: workspaceDir + "/${member}") workspaceManifest.workspace.members;

  # TODO borrow from rust-sel4
  overrides = {
    sel4-sys = {
      extraPaths = [
        "build"
      ];
    };
    sel4-bitfield-parser = {
      extraPaths = [
        "grammar.pest"
      ];
    };
    sel4-kernel-loader = {
      extraPaths = [
        "asm"
      ];
    };
    demo-mirage-unikernel-core = {
      extraPaths = [
        "c"
      ];
    };
  };

in
  crateUtils.augmentCrates
    (lib.listToAttrs (lib.forEach workspaceMemberPaths (cratePath: rec {
      name = (crateUtils.crateManifest cratePath).package.name; # TODO redundant
      value = crateUtils.mkCrate cratePath (overrides.${name} or {});
    })))

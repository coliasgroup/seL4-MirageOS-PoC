{ lib
, crateUtils
, overridesForMkCrate
}:

let
  workspaceDir = ../..;
  workspaceManifestPath = workspaceDir + "/Cargo.toml";
  workspaceManifest = builtins.fromTOML (builtins.readFile workspaceManifestPath);
  workspaceMemberPaths = map (member: workspaceDir + "/${member}") workspaceManifest.workspace.members;

  # TODO borrow from rust-sel4
  overrides = overridesForMkCrate // {
    demo-mirage-unikernel-core = {
      extraPaths = [
        "c"
      ];
    };
  };

in
  crateUtils.augmentCrates
    (lib.listToAttrs (lib.forEach workspaceMemberPaths (cratePath: rec {
      name = (crateUtils.crateManifest cratePath).package.name;
      value = crateUtils.mkCrate cratePath (overrides.${name} or {});
    })))

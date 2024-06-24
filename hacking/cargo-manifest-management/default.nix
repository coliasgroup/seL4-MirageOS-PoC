let
  depRoot = ../../rust-sel4;

in rec {
  pkgs = (import (depRoot + "/hacking/nix") {}).pkgs.build;

  inherit (pkgs) lib;

  makeBlueprint = import (depRoot + "/hacking/cargo-manifest-management/tool/make-blueprint.nix") {
    inherit lib;
  };

  parentManifestScope = import (depRoot + "/hacking/cargo-manifest-management/manifest-scope.nix") {
    inherit lib;
  };

  manifestScope = parentManifestScope // {
    mk = args: lib.recursiveUpdate
      {
        package = {
          edition = "2021";
          version = "0.1.0";
        };
      }
      args;
  };

  manualManifests =
    let
      parentManifest = builtins.fromTOML (builtins.readFile (depRoot + "/Cargo.toml"));
    in
      lib.listToAttrs (lib.forEach parentManifest.workspace.members (relPath: {
        name = (builtins.fromTOML (builtins.readFile (depRoot + "/${relPath}/Cargo.toml"))).package.name;
        value = toString (depRoot + "/${relPath}");
      }));

  workspace = makeBlueprint {
    inherit manifestScope manualManifests;
    workspaceRoot = toString ../..;
    workspaceDirFilter = relativePathSegments: lib.head relativePathSegments == "crates";
  };

  inherit (workspace) blueprint debug;

  prettyJSON = (pkgs.formats.json {}).generate;

  blueprintJSON = prettyJSON "blueprint.json" blueprint;
}

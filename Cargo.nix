{ lib, localCrates }:

{
  workspace = {
    resolver = "2";
    default-members = [];
    members = lib.naturalSort (lib.mapAttrsToList (_: v: v.path) localCrates);
  };
}

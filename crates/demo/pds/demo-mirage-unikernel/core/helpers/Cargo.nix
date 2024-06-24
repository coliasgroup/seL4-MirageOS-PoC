{ mk, localCrates, smoltcpWith }:

mk {
  package.name = "demo-mirage-unikernel-core-helpers";
  dependencies = with localCrates; {
    smoltcp = smoltcpWith [
      "log"
    ];
  };
}

self: super:

{
  this = super.this.overrideScope (thisSelf: thisSuper:
    let
      scopeName = "mirage";
    in {
      "${scopeName}" =
        let
          otherSplices = self.generateSplicesForMkScope scopeName;
        in
          self.lib.makeScopeWithSplicing
            self.splicePackages
            thisSelf.newScope
            otherSplices
            (_: {})
            (_: {})
            (subScopeSelf: thisSelf.callPackage ../scope {} subScopeSelf // {
              __dontMashWhenSplicingChildren = true;
              inherit otherSplices; # for child spliced scopes
            })
          ;
    }
  );

  inherit (self.this) mirage;
}

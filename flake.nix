{
  description = "Fuzzy Search Yazi Plugin";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    systems.url = "github:nix-systems/default";
  };

  outputs =
    {
      nixpkgs,
      systems,
      self,
      ...
    }:
    let
      inherit (nixpkgs) lib;
      forEachPkgs = f: lib.genAttrs (import systems) (system: f nixpkgs.legacyPackages.${system});
      fuzzy-search =
        {
          pkgs,
        }:
        pkgs.yaziPlugins.mkYaziPlugin {
          pname = "fuzzy-search.yazi";
          version = self.shortRev or self.dirtyShortRev or "dirty";
          src = ./src;
        };
    in
    {
      packages = forEachPkgs (pkgs: {
        default = pkgs.callPackage fuzzy-search { };
      });
    };
}

{
  description = "Zen Browser";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = {
    self,
    nixpkgs,
  }: let
    system = "x86_64-linux";

    info = builtins.fromJSON (builtins.readFile ./info.json);

    pkgs = nixpkgs.legacyPackages.${system};

    mkZen = sourceInfo: pkgs.callPackage ./package.nix {inherit sourceInfo;};
  in {
    packages."${system}" = {
      zen = mkZen {
        src = info;
        inherit (info) version;
      };
      default = self.packages.${system}.zen;
    };
  };
}

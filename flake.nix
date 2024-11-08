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
      generic = mkZen {
        variant = "generic";
        src = info.generic;
        inherit (info) version;
      };
      specific = mkZen {
        variant = "specific";
        src = info.specific;
        inherit (info) version;
      };
      default = self.packages.${system}.specific;
    };
  };
}

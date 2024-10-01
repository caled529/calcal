{
  description = "Development shells for golang";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    gomod2nix = {
      url = "github:nix-community/gomod2nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
  };

  outputs = {self, ...} @ inputs:
    with inputs.flake-utils.lib;
      eachSystem allSystems (system: let
        pkgs = import inputs.nixpkgs {
          inherit system;
          overlays = [inputs.gomod2nix.overlays.default];
        };
      in {
        packages = {
          default = pkgs.callPackage ./package.nix {};
        };
        apps = {
          default = {
            type = "app";
            program = "${self.packages."${system}".default}/bin/calcal";
          };
        };
        devShells = with pkgs; {
          default = mkShell {
            packages = [
              go
              gopls
              postgresql_16_jit
              self.packages."${system}".default
              inputs.gomod2nix.packages."${system}".default
            ];
            shellHook = ''
              ${pkgs.go}/bin/go mod tidy
              ${inputs.gomod2nix.packages."${system}".default}/bin/gomod2nix
            '';
          };
        };
      });
}

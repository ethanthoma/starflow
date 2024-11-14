{
  description = "basic flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    nix-gleam.url = "github:arnarg/nix-gleam";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      nix-gleam,
    }:
    {
      overlays = {
        default = nixpkgs.lib.composeManyExtensions [
          nix-gleam.overlays.default
        ];
      };
    }
    // flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system}.extend self.overlays.default;

        default = pkgs.buildGleamApplication {
          src = ./.;
          erlangPackage = pkgs.erlang_27;
        };
      in
      {
        checks = {
          inherit default;
        };

        packages = {
          inherit default;
        };

        devShells.default = pkgs.mkShell {
          inputsFrom = [ default ];
        };
      }
    );
}

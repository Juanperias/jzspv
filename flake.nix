{
  description = "Juan's Zig Spir V Toolchain Flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    zig-overlay = {
      url = "github:mitchellh/zig-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zls-input = {
      url = "github:zigtools/zls";
      inputs.nixpkgs.follows = "nixpkgs";

      inputs.zig-overlay.follows = "zig-overlay";
    };

    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, zig-overlay, zls-input, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ zig-overlay.overlays.default ];
        };

	zig = pkgs.zigpkgs.master;

        zls = zls-input.packages.${system}.default.overrideAttrs (old: {
          nativeBuildInputs = [ zig ];
        });
      in
      {
        devShells.default = pkgs.mkShell {
          packages = [
            zig
            zls-input.packages.${system}.default 
          ];
        };
      }
    );
}

{
  description = "Development Environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = false;
        };
      in {
        devShells.default = pkgs.mkShell {
          name = "pdfextractor";

          buildInputs = with pkgs; [
            beam28Packages.elixir_1_19
            beam28Packages.erlang
          ];
        };
      }
    );
}

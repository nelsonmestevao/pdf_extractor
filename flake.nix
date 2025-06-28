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
            # languages
            elixir_1_18
            erlang_27

            # image processing and optimization
            file
            image_optim
            nodePackages.svgo
          ];
        };
      }
    );
}

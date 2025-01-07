{
  description = "Some random bits of code";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      ...
    }:
    let
      makeBits =
        pkgs:
        {
          compiler ? "ghc948",
          doCheck ? true,
        }:
        let
          call = compiler: pkgs.haskell.packages.${compiler}.callCabal2nixWithOptions;
          src = builtins.path {
            path = ./.;
            name = "bits-src";
          };
          flags = "";
          bits_ = call compiler "bits" src flags { };
          doctest = pkgs.haskell.packages.${compiler}.doctest;
        in
        pkgs.haskell.lib.overrideCabal bits_ (_: {
          inherit doCheck;
          doHaddock = false;
          testToolDepends = [ doctest ];
        });
      overlay = final: prev: { bits = makeBits final.pkgs { }; };
    in
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ overlay ];
        };
      in
      {
        packages.bits = pkgs.bits;
        packages.default = self.packages.${system}.bits;
      }
    );
}

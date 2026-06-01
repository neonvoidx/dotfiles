{
  description = "Development shell";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nvim-config = {
      url = "github:neonvoidx/nvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ nixpkgs, ... }:
    let
      systems = nixpkgs.lib.systems.flakeExposed;
      forAllSystems = nixpkgs.lib.genAttrs systems;
      packageList =
        system: pkgs: with pkgs; [
          inputs.nvim-config.packages.${pkgs.stdenv.hostPlatform.system}.default

          # Tools & Utilities
          bash
          direnv
          yazi
          lazygit
          codex
          git
          opencode
          pay-respects
          nix-search

          # Language Runtimes
          cargo
          go
          nodejs
          python3
          python3Packages.pip
          python3Packages.pyyaml
        ];
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          default = pkgs.buildEnv {
            name = "dev-tools";
            paths = packageList system pkgs;
          };
        }
      );

      devShells = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          default = pkgs.mkShell {
            packages = packageList system pkgs;
          };
        }
      );

      formatter = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        pkgs.nixfmt
      );
    };
}

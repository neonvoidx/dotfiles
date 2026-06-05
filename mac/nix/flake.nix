{
  description = "Personal Nix packages";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nvim-config = {
      url = "github:neonvoidx/nvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nvim-config,
    }:
    let
      systems = [
        "aarch64-darwin"
        "x86_64-darwin"
      ];

      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          nvim = nvim-config.packages.${system}.default;
        in
        {
          inherit (pkgs) comma;

          inherit nvim;

          default = pkgs.symlinkJoin {
            name = "jrreed-nix-tools";
            paths = [
              nvim
              pkgs.comma
            ];
            meta.mainProgram = "nvim";
          };
        }
      );

      apps = forAllSystems (system: {
        default = self.apps.${system}.nvim;
        nvim = {
          type = "app";
          program = "${self.packages.${system}.nvim}/bin/nvim";
          meta.description = "Run Neovim from github:neonvoidx/nvim";
        };
      });

      devShells = forAllSystems (system: {
        default = nixpkgs.legacyPackages.${system}.mkShell {
          packages = [
            self.packages.${system}.nvim
            self.packages.${system}.comma
          ];
        };
      });
    };
}

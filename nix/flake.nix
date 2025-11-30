{
  description = "NeonVoid Nix";
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprland.url = "git+https://github.com/hyprwm/Hyprland?submodules=1";
    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, home-manager, ... }:
    let
      mkHost = { hostname, system ? "x86_64-linux", username, homeDirectory
        , stateVersion ? "25.05" }:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs; };
          modules = [
            ./hosts/${hostname}/configuration.nix
            ./modules/noctalia.nix
            ./modules/garbage-collection.nix
            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                users.${username} = import ./modules/home.nix;
                backupFileExtension = "backup";
                extraSpecialArgs = { inherit inputs; };
                sharedModules = [ inputs.spicetify-nix.homeManagerModules.default ];
              };
            }
          ];
        };
    in {
      nixosConfigurations = {
        voidframe = mkHost {
          hostname = "voidframe";
          username = "neonvoid";
          homeDirectory = "/home/neonvoid";
        };
      };
    };
}

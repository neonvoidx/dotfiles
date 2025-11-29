{
  description = "NeonVoid Nix"; 
  inputs = {
      nixpkgs.url = "nixpkgs/nixos-unstable";
      home-manager = {
        url = "github:nix-community/home-manager";
        inputs.nixpkgs.follows = "nixpkgs";
      };
  };
  outputs = { self, nixpkgs, home-manager, ...}: {
    nixosConfigurations.voidframe = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration.nix
        home-manager.nixosModules.home-manager 
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            users.neonvoid = import ./home.nix;
            backupFileExtension = "backup";
          };
        }
      ];
    };
  };
}

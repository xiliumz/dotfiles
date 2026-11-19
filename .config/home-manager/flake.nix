{
  description = "Home Manager configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/04906337b6d53e8bb0eaf0470ae9f070a4d4eb55";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      ...
    }:
    let
      host = import ./host.nix;

      pkgs = nixpkgs.legacyPackages.${host.system};
    in
    {
      homeConfigurations.default = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;

        extraSpecialArgs = {
          inherit host;
        };

        modules = [
          ./home.nix

          {
            home.username = host.username;
            home.homeDirectory = host.homeDirectory;
          }
        ];
      };
    };
}

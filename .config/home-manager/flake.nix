{
  description = "Home Manager configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/5adc50831c259f87faeb09ddf930d43597197473";

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

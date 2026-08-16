{
  description = "NixOS configuration for the Lenovo ThinkPad T480s";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

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
    }@inputs:
    let
      username = "skydive420dz";
      system = "x86_64-linux";
      homeDirectory = "/home/${username}";

      mkNixos =
        {
          hostname,
          hostPath,
          homeModule,
          repoName,
        }:
        let
          repoPath = "${homeDirectory}/Projects/${repoName}";
          specialArgs = {
            inherit
              inputs
              username
              hostname
              homeDirectory
              repoPath
              ;
          };
        in
        nixpkgs.lib.nixosSystem {
          inherit system specialArgs;

          modules = [
            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                extraSpecialArgs = specialArgs;
                backupFileExtension = "backup";

                users.${username}.imports = [
                  homeModule
                ];
              };
            }
            hostPath
          ];
        };
    in
    {
      nixosConfigurations = {

        t480s = mkNixos {
          hostname = "t480s";
          hostPath = ./host/t480s/system;
          homeModule = ./host/t480s/home;
          repoName = "t480s-dotfiles";
        };
      };
    };
}

{
  description = "mychine home-manager configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };

      mkHost = { username, homeDirectory ? "/home/${username}" }:
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [
            ./home.nix
            {
              home.username = username;
              home.homeDirectory = homeDirectory;
            }
          ];
        };
    in
    {
      # One entry per Linux username this gets provisioned under.
      # ansible/site.yml passes `-e hm_flake_target=<ansible_user_id>` by
      # default, so add a key here for every user account you provision.
      homeConfigurations = {
        kozaxo = mkHost { username = "kozaxo"; };
        parallels = mkHost { username = "parallels"; };
      };
    };
}

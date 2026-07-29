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
      mkHost = { username, system, homeDirectory ? "/home/${username}" }:
        let
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
        in
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
      # One entry per Linux username this gets provisioned under. `system`
      # must match that machine's actual architecture (e.g. "aarch64-linux"
      # for a Parallels VM on Apple Silicon). ansible/site.yml passes
      # `-e hm_flake_target=<ansible_user_id>` by default, so add a key here
      # for every user account you provision.
      homeConfigurations = {
        kozaxo = mkHost { username = "kozaxo"; system = "aarch64-linux"; };
        parallels = mkHost { username = "parallels"; system = "aarch64-linux"; };
      };
    };
}

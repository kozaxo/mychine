{
  description = "mychine home-manager configuration";

  inputs = {
    # Pinned to the NixOS release that shipped GNOME 46, matching Ubuntu
    # 24.04's system gnome-shell — gnomeExtensions.* built against a newer
    # GNOME (e.g. nixos-unstable) fail to load: wrong declared shell-version,
    # or JS/GObject-introspection APIs the running shell doesn't have yet.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
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

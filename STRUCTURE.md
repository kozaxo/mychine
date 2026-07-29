# Structure & intricacies

## Layout

```
ansible/
  site.yml                # entrypoint playbook
  inventory.ini           # localhost only, by default
  roles/
    base/                 # apt update + build deps
    nix/                  # installs Nix (Determinate installer)
    gui-apps/             # Brave + WezTerm via apt, sandbox fix
    home-manager/         # runs `home-manager switch` from the flake
home/
  flake.nix               # home-manager flake, one entry per username
  home.nix                # zsh, git, tmux, direnv, packages
  gnome.nix               # GNOME dconf settings, extensions, kanagawa theme
dotfiles/
  wezterm.lua             # symlinked to ~/.config/wezterm/wezterm.lua
```

Config files for the apt-installed GUI apps (currently just WezTerm) live
in `dotfiles/` and are symlinked into place by home-manager, so they stay
version-controlled even though the app itself isn't a Nix package.

## Why the split

Nix/home-manager handles user-level, declarative config well but is
awkward for GUI apps on non-NixOS: Brave and WezTerm need system-level
sandboxing/GPU driver integration that Nix packages handle poorly on
stock Ubuntu. So Ansible owns anything root/OS-level, home-manager owns
everything user-level, and the two only meet at one handoff point:
Ansible's `home-manager` role shells out to `home-manager switch`.

## `flake.nix` and `hm_flake_target`

`homeConfigurations` is keyed by Linux username, not by machine name —
there's no `default` fallback. `mkHost` requires `username` explicitly;
`homeDirectory` defaults to `/home/${username}` unless overridden.

```nix
homeConfigurations = {
  kozaxo = mkHost { username = "kozaxo"; };
  someuser = mkHost { username = "someuser"; homeDirectory = "/mnt/data/someuser"; };
};
```

`ansible/site.yml` sets `hm_flake_target: "{{ ansible_user_id }}"` by
default, so provisioning as user `alice` automatically resolves
`homeConfigurations.alice`. If that key is missing, Nix fails immediately
with "flake output attribute does not exist" — which is the point: it's
better than silently building a config for the wrong username, which is
what a hardcoded default used to do. Add a new entry for every account
you provision, or pass `-e hm_flake_target=<key>` to target one
explicitly.

Each entry also declares its own `system` (e.g. `"aarch64-linux"` for a
Parallels VM on Apple Silicon vs. `"x86_64-linux"` for a bare-metal box),
rather than one `system` shared across every `homeConfigurations` entry.
This keeps the flake pure — no `--impure`, no reading the real machine's
architecture at eval time — at the cost of having to set `system`
explicitly for every new machine, same as `username`.

## Ported from kozaxo/nix

This repo started as a port of [kozaxo/nix](https://github.com/kozaxo/nix)
(originally `username = "kozaxo"`, `/home/kozaxo`). Changes made in the
port to fit the ansible-owns-root / home-manager-owns-user split:

- The old `installBrave` home-manager activation hook is gone — Ansible's
  `gui-apps` role already apt-installs Brave.
- "Set default shell to Nix zsh" and "set default terminal to WezTerm"
  used to be home-manager activation scripts that shelled out to `sudo`.
  They're now plain Ansible tasks (`ansible/roles/home-manager` and
  `ansible/roles/gui-apps` respectively) — same effect, no sudo-from-hm.
- WezTerm's keybindings config carried over as-is into `dotfiles/wezterm.lua`.
- VS Code was originally Nix-managed with `--no-sandbox`, but now installs
  via apt (`ansible/roles/gui-apps`) the same way as Brave/WezTerm.

## Avoiding home-manager conflicts

"Conflict" covers three distinct failure modes — worth knowing which one
you're looking at.

**1. Activation won't overwrite an existing file.** The first
`home-manager switch` on a machine with any pre-existing `~/.zshrc`,
`~/.gitconfig`, `~/.tmux.conf`, or `~/.config/wezterm/wezterm.lua` aborts
with "existing file ... in the way." `ansible/roles/home-manager` already
passes `-b backup`, so those get renamed to `<file>.backup` instead of
blocking activation — but only once; if a stale `.backup` is already
there from a previous attempt, delete it before switching again.

**2. The same option is set to two different values across modules.** Nix
merges *list*-type options (`home.packages`, `home.file`, etc.) across
every imported file automatically. *Scalar* options (`home.stateVersion`,
a single `programs.git.settings.user.email`) must be defined exactly
once — redefining one in a module added later throws a "conflicting
definition values" error at build time. Keep each scalar option's
definition in a single file, or wrap an intentional override in
`lib.mkForce`.

**3. Two installers manage the same tool.** This is what actually broke
the old repo — WezTerm and Brave as Nix packages that couldn't
sandbox/render correctly on stock Ubuntu. The rule going forward: every
GUI/system tool has exactly one installer, apt (Brave, WezTerm, VS Code)
or Nix (everything in `home.packages`), never both.

This also bites you *inside* home-manager itself: don't add
`home-manager` to `home.packages`. `programs.home-manager.enable = true`
already installs it into the profile, so listing it again in
`home.packages` pulls in a second copy from a different evaluation, and
`pkgs.buildEnv` fails with "two given paths contain a conflicting
subpath" over `share/zsh/site-functions/_home-manager` when the two
copies don't byte-for-byte match.

## GNOME extensions

`gnome.nix`'s `dconf.settings` is the single source of truth — don't
hand-toggle extensions in the GNOME Extensions app, since the next
`switch` silently reverts any manual change. A newly-enabled extension
also won't load until gnome-shell restarts (log out/in, or Alt+F2 → `r`
on X11); if it's still missing after that, check
`systemctl --user show-environment | grep XDG_DATA_DIRS` includes
`$HOME/.nix-profile/share` — that's what lets gnome-shell find
Nix-installed extension schemas on non-NixOS.

## Pin your inputs

Run `nix flake lock` inside `home/` once and commit the resulting
`flake.lock`. Without it, provisioning a second machine months from now
pulls whatever nixpkgs/home-manager HEAD happens to be that day, which can
silently diverge from your first machine's config.

`nixpkgs.url` is pinned to `nixos-24.05` rather than `nixos-unstable`
specifically because `home.packages`' `gnomeExtensions.*` are compiled
JS/metadata targeting a specific GNOME shell-version, and Ubuntu is not
rolling — it ships one fixed GNOME major version per LTS release
(24.04 → GNOME 46). Building extensions from `nixos-unstable` pulls
whatever bleeding-edge GNOME (e.g. 50) unstable happens to target, which
your actual `gnome-shell --version` won't match: extensions either
declare a `shell-version` list that excludes yours (shows as "OUT OF
DATE" in `gnome-extensions info`) or load and immediately crash on a
GJS/GObject-introspection API your older shell doesn't have yet (shows
as "ERROR"). `home-manager`'s input is pinned to the matching
`release-24.05` branch for the same reason — its module API is meant to
be used together with the nixpkgs release it ships alongside, not
mixed with an arbitrary nixpkgs commit.

If you ever provision on a newer Ubuntu LTS with a newer GNOME, bump
both inputs to the matching `nixos-<version>` / `release-<version>`
pair rather than jumping to `nixos-unstable`, and re-check
`gnome-extensions info` for each extension in `gnome.nix` afterward.

## Things to customize before first run

- `home/home.nix`: `programs.git.settings.user.name`/`user.email` and the
  package list are starting points — add whatever CLI tools you actually
  use.
- `ansible/roles/gui-apps`: add more apt-installed GUI apps here the same
  way (keyring → source → apt install), and add their config files under
  `dotfiles/` + a `home.file` entry in `home.nix` if you want them
  version-controlled too.

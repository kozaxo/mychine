# mychine

One command to take a fresh Ubuntu box to a fully configured workstation,
split into two layers:

- **Ansible** (`ansible/`) — anything that needs root or touches the OS:
  installing Nix, apt-installing Brave/WezTerm/VS Code, and triggering
  `home-manager switch`.
- **home-manager** (`home/`) — dotfiles and CLI/TUI tools, fully
  declarative and versioned. See `home/home.nix`.

See [STRUCTURE.md](STRUCTURE.md) for the full directory layout, why the
split works this way, and known gotchas (home-manager conflicts, GNOME
extensions, etc.).

## Usage

On a fresh Ubuntu machine:

```bash
git clone <this-repo-url> ~/mychine
cd ~/mychine/ansible
ansible-playbook site.yml --ask-become-pass
```

That installs apt base packages, Nix, Brave, WezTerm, and applies your
home-manager config in one pass. Reruns are idempotent.

By default this applies `home/flake.nix#<your-username>`. If that key
doesn't exist yet, add it (see `home/flake.nix`'s `homeConfigurations`),
or target an existing one explicitly:

```bash
ansible-playbook site.yml --ask-become-pass -e hm_flake_target=someuser
```

## Requirements

- Ansible on the target machine itself (`sudo apt install ansible-core`
  or `pipx install ansible-core`) — this repo runs the playbook locally
  (`ansible_connection=local`), not over SSH. Add real hosts to
  `ansible/inventory.ini` if you want to provision remote boxes instead.
- Ubuntu 22.04+ (amd64 or arm64).

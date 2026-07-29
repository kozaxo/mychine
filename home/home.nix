{ pkgs, lib, ... }:
{
  imports = [ ./gnome.nix ];

  # home.username / home.homeDirectory are injected per-host in flake.nix.

  home.stateVersion = "24.05";

  # Required for standalone Home Manager on non-NixOS Linux.
  targets.genericLinux.enable = true;

  # --- packages ---
  # Brave and WezTerm are NOT here — they're apt-installed by
  # ansible/roles/gui-apps because they need system-level sandboxing/driver
  # integration Nix can't provide cleanly on non-NixOS.

  home.packages = with pkgs; [
    # system utilities
    bat
    curl
    htop
    rsync
    wget
    fastfetch

    # search & navigation
    fzf
    jq
    ripgrep

    # development
    git
    delta
    git-lfs
    lazygit
    tmux
    tmuxinator
    direnv
    podman
    podman-compose
    uv

    # security
    gnupg
    keychain

    # fonts
    fira-code # plain family, matches wezterm.lua's font name exactly
    nerd-fonts.fira-code # patched variant, for prompt/glyph icons
  ];

  # --- session / environment ---

  home.sessionPath = [
    "$HOME/.nix-profile/bin"
    "/nix/var/nix/profiles/default/bin"
  ];

  # --- zsh ---

  programs.zsh = {
    enable = true;

    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    envExtra = ''
      export PATH=$HOME/.nix-profile/bin:/nix/var/nix/profiles/default/bin:$PATH
      export PATH=$HOME/bin:/usr/local/bin:$HOME/.local/bin:$PATH
      export EDITOR="code --wait"
    '';

    initContent = lib.mkMerge [
      # keychain zstyle must be set before oh-my-zsh is sourced (order 550 < compinit 600).
      (lib.mkOrder 550 ''
        zstyle :omz:plugins:keychain agents     gpg,ssh
        zstyle :omz:plugins:keychain identities
      '')
      ''
        # cl: cd and ls combined
        function cl() {
          DIR="$*"
          if [ $# -lt 1 ]; then DIR=$HOME; fi
          builtin cd "''${DIR}" && ls -F --color=auto
        }

        # lg: lazygit — cd to repo on exit
        function lg() {
          export LAZYGIT_NEW_DIR_FILE=~/.lazygit/newdir
          lazygit "$@"
          if [ -f $LAZYGIT_NEW_DIR_FILE ]; then
            cd "$(cat $LAZYGIT_NEW_DIR_FILE)"
            rm -f $LAZYGIT_NEW_DIR_FILE > /dev/null
          fi
        }
      ''
    ];

    shellAliases = {
      ls = "ls --color=auto";
      ll = "ls -lah --color=auto";
      tcn = "mv --force -t ~/.local/share/Trash/files";
      cpv = "rsync -ah --info=progress2";
      src = "source ~/.zshrc";
      mux = "tmuxinator";
    };

    oh-my-zsh = {
      enable = true;
      theme = "gozilla";
      plugins = [
        "git"
        "history"
        "tmux"
        "gpg-agent"
        "keychain"
        "aliases"
        "alias-finder"
        "copypath"
        "copybuffer"
        "copyfile"
        "extract"
        "universalarchive"
        "direnv"
      ];
    };
  };

  # --- git ---

  programs.git = {
    enable = true;
    settings = {
      user.name = "Tanner Koza";
      user.email = "kozatanner@gmail.com";
      init.defaultBranch = "main";
      pull.rebase = false;
      push.autoSetupRemote = true;
      core.editor = "code --wait";
      core.pager = "delta";
      interactive.diffFilter = "delta --color-only";
      delta.navigate = true;
      merge.conflictStyle = "diff3";
      diff.colorMoved = "default";
      difftool.prompt = false;
      mergetool.prompt = false;
      filter.lfs = {
        clean = "git-lfs clean -- %f";
        smudge = "git-lfs smudge -- %f";
        process = "git-lfs filter-process";
        required = true;
      };
    };
    ignores = [
      ".DS_Store"
      "*.swp"
      ".direnv"
      ".envrc"
    ];
  };

  # --- direnv ---

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # --- tmux ---

  programs.tmux = {
    enable = true;
    shell = "${pkgs.zsh}/bin/zsh";
    terminal = "screen-256color";
    historyLimit = 10000;
    keyMode = "vi";
    prefix = "C-a";
    mouse = true;
    extraConfig = ''
      # split panes using | and -
      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"

      # vim-style pane navigation
      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R

      # status bar at top
      set -g status-position top
      set -g status-left-length 20

      # show pane index + title on the pane border
      set -g pane-border-format "#{pane_index} #{pane_title}"
      set -g pane-border-status bottom
    '';
  };

  # --- wezterm ---
  # wezterm itself is apt-installed (ansible/roles/gui-apps); this just
  # symlinks its config in from the repo so it's versioned.

  home.file.".config/wezterm/wezterm.lua".source = ../dotfiles/wezterm.lua;

  programs.home-manager.enable = true;
}

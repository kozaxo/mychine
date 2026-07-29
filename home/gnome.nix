{ pkgs, lib, ... }:
# GNOME desktop configuration.
# To refresh from a live system: dconf dump / > ~/dconf-backup.txt
let

  # --- everforest-gtk-theme ---
  # Not in nixpkgs, built from source using the upstream install.sh + sassc.
  # -c dark --tweaks medium produces the "Everforest-Dark-Medium" folder
  # name (see install.sh's THEME_DIR construction) — matches the dconf
  # gtk-theme/user-theme settings below.
  # -n Everforest is required, not optional: install.sh picks the theme
  # name via `${name:-$THEME_NAME}`, and Nix's stdenv always exports a
  # `$name` env var (= pname-version) for every build. Without -n, that
  # collides and silently names the theme after the derivation instead
  # (e.g. "everforest-gtk-theme-unstable-Dark-Medium").
  # First build will fail printing the correct hash; paste it in and rebuild.
  everforest-gtk-theme = pkgs.stdenv.mkDerivation {
    pname = "everforest-gtk-theme";
    version = "unstable";
    src = pkgs.fetchFromGitHub {
      owner = "Fausto-Korpsvart";
      repo = "Everforest-GTK-Theme";
      rev = "master";
      hash = "sha256-XHO6NoXJwwZ8gBzZV/hJnVq5BvkEKYWvqLBQT00dGdE=";
    };
    nativeBuildInputs = [ pkgs.sassc pkgs.gtk-engine-murrine ];
    installPhase = ''
      runHook preInstall
      mkdir -p $out/share/themes
      bash themes/install.sh -d $out/share/themes -n Everforest -c dark --tweaks medium
      runHook postInstall
    '';
  };

  # --- everforest-icon-theme ---
  # Same upstream repo as the GTK theme; icons/ ships pre-built, no build step.
  everforest-icon-theme = pkgs.stdenv.mkDerivation {
    pname = "everforest-icon-theme";
    version = "unstable";
    src = everforest-gtk-theme.src; # reuse the same fetch, no extra download
    nativeBuildInputs = [ pkgs.hicolor-icon-theme ];
    installPhase = ''
      runHook preInstall
      mkdir -p $out/share/icons
      cp -r icons/Everforest-Dark $out/share/icons/
      runHook postInstall
    '';
  };

in
{
  # --- packages ---

  # GNOME Shell extensions are NOT here — they're installed by
  # ansible/roles/gnome-extensions from extensions.gnome.org, matched to
  # this machine's actual gnome-shell version. gnomeExtensions.* packages
  # are compiled against whatever GNOME version this flake's nixpkgs
  # happens to target, which silently drifts from Ubuntu's fixed
  # per-LTS-release shell version and breaks at runtime (OUT OF DATE /
  # ERROR — see STRUCTURE.md).

  home.packages = with pkgs; [
    # theme dependencies & tooling
    gtk-engine-murrine # required by many GTK2/3 themes
    gnome-tweaks
    yaru-theme # provides the Yaru cursor

    # custom themes (built above)
    everforest-gtk-theme
    everforest-icon-theme
  ];

  # --- dconf ---

  dconf.settings = {

    # --- interface ---

    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      clock-show-seconds = true;
      clock-show-weekday = false;
      font-hinting = "slight";
      gtk-theme = "Everforest-Dark-Medium";
      icon-theme = "Everforest-Dark";
      cursor-theme = "Yaru";
    };

    # --- session ---

    "org/gnome/desktop/session" = {
      idle-delay = lib.hm.gvariant.mkUint32 0;
    };

    # --- input ---

    "org/gnome/desktop/input-sources" = {
      per-window = false;
      sources = [ (lib.hm.gvariant.mkTuple [ "xkb" "us" ]) ];
      xkb-options = [ "compose:caps" ];
    };

    # --- power ---

    "org/gnome/settings-daemon/plugins/power" = {
      sleep-inactive-ac-timeout = 3600;
      sleep-inactive-ac-type = "nothing";
    };

    # --- workspaces ---

    "org/gnome/desktop/wm/preferences" = {
      workspace-names = [ "home" ];
    };

    # --- mutter ---
    # PaperWM manages tiling so edge-tiling is off.

    "org/gnome/mutter" = {
      attach-modal-dialogs = false;
      edge-tiling = false;
      overlay-key = "Super_L";
      workspaces-only-on-primary = false;
    };

    "org/gnome/mutter/keybindings" = {
      toggle-tiled-left = [ "<Super>Left" ];
      toggle-tiled-right = [ "<Super>Right" ];
    };

    "org/gnome/mutter/wayland/keybindings" = {
      restore-shortcuts = [ ];
    };

    # --- WM keybindings ---
    # Cleared because PaperWM overrides them all.

    "org/gnome/desktop/wm/keybindings" = {
      maximize = [ ];
      minimize = [ ];
      move-to-monitor-down = [ ];
      move-to-monitor-left = [ ];
      move-to-monitor-right = [ ];
      move-to-monitor-up = [ ];
      switch-applications = [ ];
      switch-applications-backward = [ ];
      switch-group = [ ];
      switch-group-backward = [ ];
      switch-to-workspace-1 = [ ];
      switch-to-workspace-last = [ ];
      switch-to-workspace-left = [ ];
      switch-to-workspace-right = [ ];
      unmaximize = [ ];
    };

    # --- shell keybindings ---
    # Cleared — PaperWM takes over overview navigation.

    "org/gnome/shell/keybindings" = {
      focus-active-notification = [ ];
      shift-overview-down = [ ];
      shift-overview-up = [ ];
    };

    # --- media keys ---

    "org/gnome/settings-daemon/plugins/media-keys" = {
      screensaver = [ ];
      terminal = [ ];
      custom-keybindings = [
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
      ];
    };

    # Ctrl+Alt+T → WezTerm (apt-installed, so plain `wezterm` on PATH is correct)
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
      binding = "<Primary><Alt>t";
      command = "wezterm";
      name = "WezTerm";
    };

    # --- shell ---

    "org/gnome/shell" = {
      disable-user-extensions = false;
      disabled-extensions = [ "ding@rastersoft.com" "ubuntu-dock@ubuntu.com" ];
      enabled-extensions = [
        "dash-to-dock@micxgx.gmail.com"
        "arcmenu@arcmenu.com"
        "user-theme@gnome-shell-extensions.gcampax.github.com"
        "Vitals@CoreCoding.com"
        "paperwm@paperwm.github.com"
      ];
      favorite-apps = [
        "org.gnome.Nautilus.desktop"
        "code.desktop"
        "brave-browser.desktop"
      ];
    };

    # --- user-theme extension ---

    "org/gnome/shell/extensions/user-theme" = {
      name = "Everforest-Dark-Medium";
    };

    # --- dash-to-dock ---

    "org/gnome/shell/extensions/dash-to-dock" = {
      background-opacity = 0.8;
      dash-max-icon-size = 48;
      dock-position = "RIGHT";
      height-fraction = 0.9;
      preferred-monitor = -2;
    };

    # --- arcmenu ---

    "org/gnome/shell/extensions/arcmenu" = {
      enable-menu-hotkey = true;
      menu-background-color = "rgb(45,53,59)";
      menu-border-color = "rgb(71,82,88)";
      menu-button-appearance = "Icon";
      menu-foreground-color = "rgb(211,198,170)";
      menu-item-active-bg-color = "rgba(167,192,128,0.15)";
      menu-item-active-fg-color = "rgb(255,255,255)";
      menu-item-hover-bg-color = "rgba(131,192,146,0.08)";
      menu-item-hover-fg-color = "rgb(255,255,255)";
      menu-layout = "Plasma";
      menu-separator-color = "rgb(71,82,88)";
      override-menu-theme = true;
      position-in-panel = "Center";
      search-entry-border-radius = lib.hm.gvariant.mkTuple [
        true
        (lib.hm.gvariant.mkInt32 25)
      ];
      show-activities-button = false;
    };

    # --- vitals ---

    "org/gnome/shell/extensions/vitals" = {
      alphabetize = false;
      fixed-widths = true;
      hide-icons = false;
      hot-sensors = [
        "_memory_usage_"
        "__network-rx_max__"
        "_processor_usage_"
        "_storage_free_"
      ];
      show-battery = false;
      show-storage = true;
      storage-measurement = 0;
      storage-path = "/";
      use-higher-precision = false;
    };

    # --- paperwm ---

    "org/gnome/shell/extensions/paperwm" = {
      horizontal-margin = 30;
      vertical-margin = 30;
      vertical-margin-bottom = 30;
      window-gap = 30;
      show-window-position-bar = false;
      use-default-background = true;
      disable-scratch-in-overview = false;
      only-scratch-in-overview = false;
    };

    "org/gnome/shell/extensions/paperwm/keybindings" = {
      move-down = [ "<Control><Super>Down" ];
      move-down-workspace = [ "<Control><Super>Page_Down" "<Shift><Super>j" ];
      move-left = [
        "<Control><Super>comma"
        "<Shift><Super>comma"
        "<Control><Super>Left"
        "<Shift><Super>h"
      ];
      move-right = [
        "<Control><Super>period"
        "<Shift><Super>period"
        "<Control><Super>Right"
        "<Shift><Super>l"
      ];
      move-up = [ "<Control><Super>Up" ];
      move-up-workspace = [ "<Control><Super>Page_Up" "<Shift><Super>k" ];
      switch-down-workspace = [ "<Super>j" ];
      switch-left = [ "<Super>h" ];
      switch-right = [ "<Super>l" ];
      switch-up-workspace = [ "<Super>k" ];
    };

    # --- nautilus ---

    "org/gnome/nautilus/preferences" = {
      default-folder-viewer = "list-view";
      search-view = "list-view";
      search-filter-time-type = "last_modified";
    };

  };
}

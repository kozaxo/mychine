# Single place recording the current desktop "look" — GTK/icon/shell theme
# names, ArcMenu's accent colors, and WezTerm's font/color scheme. Reskinning
# should mean editing values here first, rather than hunting through
# gnome.nix + dotfiles/wezterm.lua separately.
#
# What this can't cover: GTK/icon themes and WezTerm color schemes are
# pre-built assets (Nix derivations pulling upstream repos, or WezTerm's
# bundled Gogh schemes) with their own baked-in palettes — this file can't
# derive their actual colors, only record *which* one is currently chosen.
# Swapping to a genuinely different theme (not just re-pointing to a new
# name) still means changing the fetchFromGitHub source in gnome.nix's
# theme derivations.
#
# WezTerm specifically: Lua can't import this file directly, so
# dotfiles/wezterm.lua's config.font/config.color_scheme are NOT derived
# from `wezterm` below — they're just recorded here too, so a reskin pass
# doesn't forget to update wezterm.lua to match.
{
  # Built by the `everforest-gtk-theme` derivation in gnome.nix.
  gtk = {
    # Passed to install.sh's -n flag — see that derivation's comment for
    # why this can't just be left at the script's own default.
    baseName = "Everforest";
    # Full folder name after install.sh's -c/--tweaks suffixes are
    # appended (-c dark --tweaks medium -> "-Dark-Medium"). Used for both
    # gtk-theme and the user-theme extension's name.
    name = "Everforest-Dark-Medium";
  };

  # Built by the `kora-icon-theme` derivation in gnome.nix.
  icon.name = "kora";

  cursor.name = "Yaru";

  # org/gnome/shell/extensions/arcmenu colors in gnome.nix.
  arcmenu = {
    background = "rgb(45,53,59)";
    border = "rgb(71,82,88)";
    foreground = "rgb(211,198,170)";
    activeBg = "rgba(167,192,128,0.15)";
    activeFg = "rgb(255,255,255)";
    hoverBg = "rgba(131,192,146,0.08)";
    hoverFg = "rgb(255,255,255)";
    separator = "rgb(71,82,88)";
  };

  # Recorded, not derived — see file header. Must match dotfiles/wezterm.lua.
  wezterm = {
    font = "JetBrains Mono";
    colorScheme = "Everforest Dark Medium (Gogh)";
  };
}

#!/usr/bin/env bash
# hyprland-macos-theme installer — macOS look for Hyprland (Lua config) + Dux Shell (dms)
#
#   ./install.sh                  everything
#   ./install.sh --no-deps        skip pacman packages
#   ./install.sh --no-third-party skip MacTahoe / WhiteSur / macOS cursor downloads
#
# Every file that gets replaced is copied first to ~/.config/hyprland-macos-backup-<date>/
set -euo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)
CONF=${XDG_CONFIG_HOME:-$HOME/.config}
BACKUP="$CONF/hyprland-macos-backup-$(date +%Y%m%d-%H%M%S)"
DEPS=1
THIRD=1

for arg in "$@"; do
    case $arg in
        --no-deps) DEPS=0 ;;
        --no-third-party) THIRD=0 ;;
        -h|--help) sed -n '2,8p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) echo "unknown option: $arg" >&2; exit 1 ;;
    esac
done

say()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*"; }

backup() {
    [ -e "$1" ] || [ -L "$1" ] || return 0
    local rel=${1#"$HOME"/}
    mkdir -p "$BACKUP/$(dirname "$rel")"
    cp -a "$1" "$BACKUP/$rel"
}

put() { # put SRC DST — install a file, keeping a backup of the old one
    backup "$2"
    mkdir -p "$(dirname "$2")"
    cp -a "$1" "$2"
}

# ------------------------------------------------------------------ packages
if [ "$DEPS" = 1 ]; then
    if command -v pacman >/dev/null; then
        say "Installing packages (fonts, Kvantum, qt6ct, build tools)"
        sudo pacman -S --needed inter-font ttf-jetbrains-mono-nerd kvantum qt6ct \
            git curl tar xz sassc glib2 libxml2 python
    else
        warn "Not an Arch system: install Inter, JetBrains Mono Nerd Font, Kvantum, qt6ct, git, curl, sassc yourself"
    fi
fi

# ------------------------------------------------------- third-party themes
if [ "$THIRD" = 1 ]; then
    tmp=$(mktemp -d)
    trap 'rm -rf "$tmp"' EXIT

    say "MacTahoe GTK theme (vinceliuice/MacTahoe-gtk-theme, MIT)"
    git clone --depth 1 -q https://github.com/vinceliuice/MacTahoe-gtk-theme "$tmp/gtk"
    (cd "$tmp/gtk" && ./install.sh)

    say "MacTahoe icons (vinceliuice/MacTahoe-icon-theme, GPL-3.0)"
    git clone --depth 1 -q https://github.com/vinceliuice/MacTahoe-icon-theme "$tmp/icons"
    (cd "$tmp/icons" && ./install.sh)

    say "WhiteSur Kvantum theme for Qt apps (vinceliuice/WhiteSur-kde, GPL-3.0)"
    git clone --depth 1 -q https://github.com/vinceliuice/WhiteSur-kde "$tmp/kde"
    mkdir -p "$CONF/Kvantum"
    backup "$CONF/Kvantum/WhiteSur"
    rm -rf "$CONF/Kvantum/WhiteSur"
    cp -r "$tmp/kde/Kvantum/WhiteSur" "$CONF/Kvantum/"

    say "macOS cursor (ful1e5/apple_cursor, GPL-3.0)"
    mkdir -p "$HOME/.icons"
    curl -fsSL https://github.com/ful1e5/apple_cursor/releases/latest/download/macOS.tar.xz \
        | tar -xJ -C "$HOME/.icons"
fi

# ---------------------------------------------------------------- Hyprland
say "Hyprland: macos.lua + light/dark appearance script"
put "$HERE/hypr/macos.lua" "$CONF/hypr/macos.lua"
put "$HERE/hypr/scripts/mac-appearance.sh" "$CONF/hypr/scripts/mac-appearance.sh"
chmod +x "$CONF/hypr/scripts/mac-appearance.sh"

if [ -f "$CONF/hypr/hyprland.lua" ]; then
    if ! grep -q 'require("macos")' "$CONF/hypr/hyprland.lua"; then
        backup "$CONF/hypr/hyprland.lua"
        printf '\n-- macOS look (hyprland-macos-theme)\nrequire("macos")\n' >> "$CONF/hypr/hyprland.lua"
    fi
else
    warn "No ~/.config/hypr/hyprland.lua: this theme needs the Lua config (Hyprland 0.57+)."
    warn "Add  require(\"macos\")  to your hyprland.lua once you have one."
fi

# --------------------------------------------------------------- Dux Shell
say "Dux Shell: macOS theme, Spotlight icon, Mac App Menu plugin, look settings"
put "$HERE/dms/themes/macos.json" "$CONF/dms/themes/macos.json"
put "$HERE/dms/icons/spotlight.svg" "$CONF/dms/icons/spotlight.svg"
backup "$CONF/dms/plugins/macAppMenu"
mkdir -p "$CONF/dms/plugins"
rm -rf "$CONF/dms/plugins/macAppMenu"
cp -r "$HERE/dms/plugins/macAppMenu" "$CONF/dms/plugins/"

backup "$CONF/dms/settings.json"
backup "$CONF/dms/plugin_settings.json"
python3 - "$CONF/dms" "$HERE/dms/settings-preset.json" "$HOME" <<'EOF'
import json, os, sys
dms, preset_path, home = sys.argv[1:4]

def merge(path, update):
    data = {}
    if os.path.exists(path):
        with open(path) as f:
            data = json.load(f)
    update(data)
    # rewrite in place: keeps the file's owner, group and permissions
    with open(path, "r+" if os.path.exists(path) else "w") as f:
        f.seek(0)
        json.dump(data, f, indent=2, ensure_ascii=False)
        f.truncate()

preset = json.loads(open(preset_path).read().replace("__HOME__", home))
merge(os.path.join(dms, "settings.json"), lambda d: d.update(preset))
merge(os.path.join(dms, "plugin_settings.json"),
      lambda d: d.setdefault("macAppMenu", {}).update(enabled=True))
EOF

# ------------------------------------------------------------------- kitty
if command -v kitty >/dev/null || [ -d "$CONF/kitty" ]; then
    say "kitty: macOS dark/light palettes"
    put "$HERE/kitty/macos.conf" "$CONF/kitty/macos.conf"
    put "$HERE/kitty/macos-light.conf" "$CONF/kitty/macos-light.conf"
    [ -e "$CONF/kitty/macos-current.conf" ] || ln -s macos.conf "$CONF/kitty/macos-current.conf"
    if ! grep -qs 'include ./macos-current.conf' "$CONF/kitty/kitty.conf"; then
        backup "$CONF/kitty/kitty.conf"
        { echo "include ./macos-current.conf"; cat "$CONF/kitty/kitty.conf" 2>/dev/null || true; } \
            > "$CONF/kitty/kitty.conf.new"
        mv "$CONF/kitty/kitty.conf.new" "$CONF/kitty/kitty.conf"
    fi
fi

# ------------------------------------------------------------- GTK and Qt
say "GTK, icons, cursor and fonts"
if command -v gsettings >/dev/null; then
    gsettings set org.gnome.desktop.interface gtk-theme 'MacTahoe-Dark'
    gsettings set org.gnome.desktop.interface icon-theme 'MacTahoe'
    gsettings set org.gnome.desktop.interface cursor-theme 'macOS'
    gsettings set org.gnome.desktop.interface cursor-size 24
    gsettings set org.gnome.desktop.interface font-name 'Inter Variable 10'
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
fi
backup "$CONF/gtk-3.0/settings.ini"
python3 - "$CONF/gtk-3.0/settings.ini" <<'EOF'
import os, sys
path = sys.argv[1]
want = {
    "gtk-theme-name": "MacTahoe-Dark",
    "gtk-icon-theme-name": "MacTahoe",
    "gtk-cursor-theme-name": "macOS",
    "gtk-cursor-theme-size": "24",
    "gtk-font-name": "Inter Variable 10",
    "gtk-application-prefer-dark-theme": "1",
    "gtk-decoration-layout": ":",
}
lines = open(path).read().splitlines() if os.path.exists(path) else ["[Settings]"]
if "[Settings]" not in lines:
    lines.insert(0, "[Settings]")
seen = set()
for i, line in enumerate(lines):
    key = line.split("=", 1)[0].strip()
    if key in want:
        lines[i] = f"{key}={want[key]}"
        seen.add(key)
lines += [f"{k}={v}" for k, v in want.items() if k not in seen]
os.makedirs(os.path.dirname(path), exist_ok=True)
open(path, "w").write("\n".join(lines) + "\n")
EOF
mkdir -p "$CONF/gtk-4.0"
backup "$CONF/Kvantum/kvantum.kvconfig"
mkdir -p "$CONF/Kvantum"
printf '[General]\ntheme=WhiteSurDark\n' > "$CONF/Kvantum/kvantum.kvconfig"

# GTK 4 / libadwaita, Kvantum and kitty follow the current light/dark mode
"$CONF/hypr/scripts/mac-appearance.sh" apply || warn "mac-appearance.sh apply failed (is MacTahoe installed?)"

command -v hyprctl >/dev/null && hyprctl reload >/dev/null 2>&1 || true

say "Done. Log out and back in so Dux Shell and every app pick up the new theme."
[ -d "$BACKUP" ] && say "Your previous files are saved in $BACKUP"

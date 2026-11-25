# hyprland-macos-theme

A macOS look for **Hyprland** (Lua config, 0.57+) and the **Dux Shell** (`dms`) desktop shell: Apple system colours, a menu bar with a bold app menu, Spotlight-style launcher, frosted blur, soft window shadows, macOS-like animations, and apps that follow light/dark mode.

## What you get

- **Dux Shell theme "macOS · Arch"**: Apple system palette for dark and light mode (`dms/themes/macos.json`)
- **Mac App Menu** plugin: the bold app name in the menu bar, with About, Hide, Quit, Force Quit… (`dms/plugins/macAppMenu`)
- **Menu bar and dock preset**: launcher, app menu, workspace dots, tray, battery, control center, Spotlight button and clock; dock with magnification
- **Hyprland look** (`hypr/macos.lua`): 12 px rounded corners, hairline borders, large soft drop shadows, frosted blur, ease-out "pop-in" windows and sliding workspaces
- **Light/dark sync** (`hypr/scripts/mac-appearance.sh`): when the shell switches mode, GTK 3/4 (MacTahoe), Qt (Kvantum WhiteSur) and kitty switch too
- **kitty** dark and light palettes with Apple system colours
- GTK theme, icons, cursor and fonts set to MacTahoe, macOS cursor and Inter

## Requirements

- Hyprland 0.57+ with a Lua config (`~/.config/hypr/hyprland.lua`)
- Dux Shell (`dms`) as the desktop shell
- Arch Linux for the automatic package install (other distros: install the packages listed in `install.sh` by hand and use `--no-deps`)

## Install

```sh
git clone https://github.com/CyberMer/hyprland-macos-theme
cd hyprland-macos-theme
./install.sh
```

Then log out and back in.

Options: `--no-deps` skips the pacman packages, `--no-third-party` skips downloading MacTahoe, WhiteSur and the macOS cursor.

The installer:

1. installs Inter, JetBrains Mono Nerd Font, Kvantum and qt6ct (pacman)
2. downloads and installs the third-party themes from their own repositories (see Credits)
3. copies `macos.lua` and `mac-appearance.sh` into `~/.config/hypr` and adds `require("macos")` at the end of your `hyprland.lua`
4. installs the Dux Shell theme, Spotlight icon and Mac App Menu plugin, and merges the look settings into `~/.config/dms/settings.json` (your other settings are kept, and so are the file's permissions)
5. sets the GTK theme, icons, cursor and font, and adds the macOS palettes to kitty

Every file it replaces is copied first to `~/.config/hyprland-macos-backup-<date>/`.

## Uninstall

Copy the files back from `~/.config/hyprland-macos-backup-<date>/` and remove the `require("macos")` line from `hyprland.lua`.

## Credits

Downloaded by the installer, not included in this repository:

- [MacTahoe GTK theme](https://github.com/vinceliuice/MacTahoe-gtk-theme) by vinceliuice (MIT)
- [MacTahoe icon theme](https://github.com/vinceliuice/MacTahoe-icon-theme) by vinceliuice (GPL-3.0)
- [WhiteSur Kvantum theme](https://github.com/vinceliuice/WhiteSur-kde) by vinceliuice (GPL-3.0)
- [macOS cursor](https://github.com/ful1e5/apple_cursor) by ful1e5 (GPL-3.0)
- [Inter](https://rsms.me/inter/) font by Rasmus Andersson (OFL)

Wallpapers are not included: the macOS wallpapers belong to Apple.

Not affiliated with or endorsed by Apple. macOS is a trademark of Apple Inc.

## See also

- [wvkbd-ipad](https://github.com/CyberMer/wvkbd-ipad): iPad-style on-screen keyboard for Wayland
- [dotfiles](https://github.com/CyberMer/dotfiles): my full Hyprland configuration

## License

MIT for the files in this repository. The third-party themes keep their own licenses.

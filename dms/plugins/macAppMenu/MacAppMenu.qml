import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins

// macOS menu bar for DMS: the active app's name in bold, then File · Edit · View · Window · Help.
// The menus adapt to the kind of app (browser, terminal, editor, files) and send the usual keyboard
// shortcuts to the window with Hyprland's send_shortcut — the same approach MacShell uses.
PluginComponent {
    id: root
    pluginId: "macAppMenu"

    readonly property var toplevel: ToplevelManager.activeToplevel
    readonly property string appId: toplevel ? (toplevel.appId || "") : ""
    readonly property var desktopEntry: appId ? DesktopEntries.heuristicLookup(Paths.moddedAppId(appId)) : null
    readonly property string appName: appId ? Paths.getAppName(appId, desktopEntry) : "Desktop"
    readonly property bool hasApp: appId !== ""
    readonly property string kind: {
        const id = appId.toLowerCase();
        if (/kitty|alacritty|foot|wezterm|ghostty|konsole|terminal/.test(id)) return "terminal";
        if (/brave|firefox|chrom|zen|librewolf|vivaldi|floorp|epiphany/.test(id)) return "browser";
        if (/thunar|nautilus|dolphin|nemo|pcmanfm|files/.test(id)) return "files";
        if (/code|zed|kate|gedit|text|neovide|obsidian|jetbrains|idea|pycharm|sublime/.test(id)) return "editor";
        return "app";
    }
    property string menu: "app"          // which menu the popout shows
    readonly property var menus: hasApp ? ["File", "Edit", "View", "Window", "Help"] : ["File", "Help"]

    // ── actions ──
    function sh(cmd) { Quickshell.execDetached(["sh", "-c", cmd]); }
    function lua(code) { Quickshell.execDetached(["hyprctl", "dispatch", "function() " + code + " end"]); }
    // send a shortcut to the app window (the menu popout never takes the window's place as "active window")
    function keys(mods, key) {
        return () => lua("local w = hl.get_active_window() or hl.get_last_window(); if w then hl.dispatch(hl.dsp.send_shortcut({ mods = '"
                         + mods + "', key = '" + key + "', window = 'address:' .. w.address })) end");
    }
    function win(code) {   // a Hyprland window action on the app window
        return () => lua("local w = hl.get_active_window() or hl.get_last_window(); if w then local s = 'address:' .. w.address; " + code + " end");
    }
    function run(cmd) { return () => sh(cmd); }
    function act(fn) { root.closePopout(); Qt.callLater(fn); }

    function mi(label, key, fn, enabled) { return { label: label, key: key || "", run: fn, enabled: enabled !== false }; }
    readonly property var sepItem: ({ sep: true })

    function itemsFor(name) {
        const term = kind === "terminal", browser = kind === "browser", files = kind === "files", editor = kind === "editor";
        const n = appName, m = [];
        if (name === "app") {
            m.push(mi("About This Arch", "", run("about-this-arch")), sepItem,
                   mi("System Settings…", "", run("dms ipc call settings toggle")),
                   mi("Force Quit…", "", run("dms ipc call processlist toggle")), sepItem);
            if (hasApp) m.push(mi("Hide " + n, "", win("hl.dispatch(hl.dsp.window.move({ workspace = 'special:hidden', follow = false, window = s }))")));
            m.push(mi("Show Hidden Windows", "", () => lua("hl.dispatch(hl.dsp.workspace.toggle_special('hidden'))")), sepItem);
            if (hasApp) m.push(mi("Quit " + n, "", win("hl.dispatch(hl.dsp.window.close({ window = s }))")), sepItem);
            m.push(mi("Lock Screen", "", run("dms ipc call lock lock")),
                   mi("Restart / Shut Down…", "", run("dms ipc call powermenu toggle")));
        } else if (name === "File") {
            if (!hasApp) {
                m.push(mi("New Terminal", "", run("kitty")), mi("Open Home Folder", "", run("thunar")));
            } else {
                if (browser) m.push(mi("New Window", "Ctrl+N", keys("CTRL", "n")), mi("New Private Window", "Ctrl+Shift+N", keys("CTRL SHIFT", "n")));
                if (browser || files) m.push(mi("New Tab", "Ctrl+T", keys("CTRL", "t")));
                if (term) m.push(mi("New Tab", "Ctrl+Shift+T", keys("CTRL SHIFT", "t")));
                if (browser) m.push(mi("Reopen Closed Tab", "Ctrl+Shift+T", keys("CTRL SHIFT", "t")));
                if (!term && !files) m.push(mi("Open…", "Ctrl+O", keys("CTRL", "o")), sepItem,
                                            mi(browser ? "Save Page As…" : "Save", "Ctrl+S", keys("CTRL", "s")));
                if (editor) m.push(mi("Save As…", "Ctrl+Shift+S", keys("CTRL SHIFT", "s")));
                if (!term && !files) m.push(mi("Print…", "Ctrl+P", keys("CTRL", "p")));
                m.push(sepItem);
                if (term) m.push(mi("Close Tab", "Ctrl+Shift+W", keys("CTRL SHIFT", "w")));
                else m.push(mi("Close Tab", "Ctrl+W", keys("CTRL", "w")));
                m.push(mi("Close Window", "", win("hl.dispatch(hl.dsp.window.close({ window = s }))")));
            }
            m.push(sepItem, mi("Screenshot…", "", run("~/.config/hypr/scripts/screenshot.sh")));
        } else if (name === "Edit") {
            if (term) {
                m.push(mi("Copy", "Ctrl+Shift+C", keys("CTRL SHIFT", "c")), mi("Paste", "Ctrl+Shift+V", keys("CTRL SHIFT", "v")));
            } else {
                m.push(mi("Undo", "Ctrl+Z", keys("CTRL", "z")), mi("Redo", "Ctrl+Shift+Z", keys("CTRL SHIFT", "z")), sepItem,
                       mi("Cut", "Ctrl+X", keys("CTRL", "x")), mi("Copy", "Ctrl+C", keys("CTRL", "c")), mi("Paste", "Ctrl+V", keys("CTRL", "v")),
                       mi("Select All", "Ctrl+A", keys("CTRL", "a")), sepItem, mi("Find…", "Ctrl+F", keys("CTRL", "f")));
            }
            m.push(sepItem, mi("Clipboard History…", "", run("dms ipc call clipboard toggle")));
        } else if (name === "View") {
            m.push(mi("Enter Full Screen", "", win("hl.dispatch(hl.dsp.window.fullscreen({ mode = 'fullscreen', action = 'toggle', window = s }))")),
                   mi("Float / Tile Window", "", win("hl.dispatch(hl.dsp.window.float({ action = 'toggle', window = s }))")),
                   mi("Toggle Split Direction", "", () => lua("hl.dispatch(hl.dsp.layout('togglesplit'))")));
            if (!term) m.push(sepItem, mi("Actual Size", "Ctrl+0", keys("CTRL", "0")),
                              mi("Zoom In", "Ctrl++", keys("CTRL", "equal")), mi("Zoom Out", "Ctrl+-", keys("CTRL", "minus")));
            if (browser || files) m.push(sepItem, mi("Reload", "F5", keys("", "F5")));
            if (browser) m.push(mi("Developer Tools", "F12", keys("", "F12")));
        } else if (name === "Window") {
            m.push(mi("Minimize", "", win("hl.dispatch(hl.dsp.window.move({ workspace = 'special:hidden', follow = false, window = s }))")),
                   mi("Zoom", "", win("hl.dispatch(hl.dsp.window.fullscreen({ mode = 'maximized', action = 'toggle', window = s }))")),
                   mi("Center", "", win("hl.dispatch(hl.dsp.window.float({ action = 'enable', window = s })); hl.dispatch(hl.dsp.window.center())")),
                   sepItem,
                   mi("Move to Next Workspace", "", win("hl.dispatch(hl.dsp.window.move({ workspace = 'e+1', window = s }))")),
                   mi("Move to Previous Workspace", "", win("hl.dispatch(hl.dsp.window.move({ workspace = 'e-1', window = s }))")),
                   sepItem,
                   mi("Workspace Overview", "Super+O", run("dms ipc call hypr toggleOverview")));
        } else if (name === "Help") {
            m.push(mi("Keyboard Shortcuts", "Super+/", run("dms ipc call keybinds toggle")), sepItem,
                   mi("Arch Wiki", "", run("xdg-open https://wiki.archlinux.org")),
                   mi("Hyprland Wiki", "", run("xdg-open https://wiki.hypr.land")));
        }
        return m;
    }

    function open(name) {
        root.menu = name;
        root.triggerPopout();
    }

    popoutWidth: 260

    horizontalBarPill: Component {
        Row {
            spacing: 0
            // the app name opens the app menu (About, Hide, Quit…)
            Item {
                width: appText.implicitWidth + 14
                height: appText.implicitHeight + 6
                StyledText {
                    id: appText
                    anchors.centerIn: parent
                    text: root.appName
                    font.pixelSize: Theme.fontSizeMedium
                    font.weight: Font.Bold
                    color: Theme.surfaceText
                    elide: Text.ElideRight
                    width: Math.min(implicitWidth, 200)
                }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.open("app") }
            }
            Repeater {
                model: root.menus
                delegate: Item {
                    required property string modelData
                    width: lbl.implicitWidth + 16
                    height: lbl.implicitHeight + 6
                    Rectangle {
                        anchors.fill: parent
                        radius: 5
                        color: ma.containsMouse ? Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.12) : "transparent"
                    }
                    StyledText {
                        id: lbl
                        anchors.centerIn: parent
                        text: modelData
                        font.pixelSize: Theme.fontSizeMedium
                        color: Theme.surfaceText
                    }
                    MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.open(modelData) }
                }
            }
        }
    }

    verticalBarPill: Component {
        StyledText {
            text: root.appName.charAt(0)
            font.pixelSize: Theme.fontSizeMedium
            font.weight: Font.Bold
            color: Theme.surfaceText
        }
    }

    popoutContent: Component {
        Item {
            implicitWidth: 260
            implicitHeight: list.implicitHeight + 12

            Column {
                id: list
                anchors.fill: parent
                anchors.margins: 6
                spacing: 0

                Repeater {
                    model: root.itemsFor(root.menu)
                    delegate: Item {
                        required property var modelData
                        readonly property bool on: !modelData.sep && modelData.enabled
                        width: list.width
                        height: modelData.sep ? 9 : 26

                        Rectangle {
                            visible: !!modelData.sep
                            anchors.verticalCenter: parent.verticalCenter
                            x: 8; width: parent.width - 16; height: 1
                            color: Theme.outline
                            opacity: 0.4
                        }
                        Rectangle {
                            visible: !modelData.sep
                            anchors.fill: parent
                            radius: 6
                            color: area.containsMouse && on ? Theme.primary : "transparent"
                            StyledText {
                                anchors.left: parent.left; anchors.leftMargin: 10
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.label || ""
                                font.pixelSize: Theme.fontSizeMedium
                                color: area.containsMouse && on ? Theme.primaryText : Theme.surfaceText
                                opacity: on ? 1 : 0.4
                            }
                            StyledText {
                                anchors.right: parent.right; anchors.rightMargin: 10
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.key || ""
                                font.pixelSize: Theme.fontSizeSmall
                                color: area.containsMouse && on ? Theme.primaryText : Theme.surfaceVariantText
                            }
                            MouseArea {
                                id: area
                                anchors.fill: parent
                                hoverEnabled: true
                                enabled: on
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.act(modelData.run)
                            }
                        }
                    }
                }
            }
        }
    }
}

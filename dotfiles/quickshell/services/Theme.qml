pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    readonly property color fallbackAccent: "#7aa2f7"
    property color accent: fallbackAccent

    // Text/icon color for on top of `accent`, picked by relative luminance
    // so it stays readable regardless of the active theme's accent.
    readonly property color onAccent: (0.299 * accent.r + 0.587 * accent.g + 0.114 * accent.b) > 0.6 ? "black" : "white"

    readonly property FileView colorsFile: FileView {
        path: Quickshell.env("HOME") + "/.local/state/my_theme/colors.css"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root._applyColors(text())
        onLoadFailed: root.accent = root.fallbackAccent
    }

    function _applyColors(css) {
        const match = /@define-color\s+accent\s+(#[0-9a-fA-F]{6})/.exec(css)
        root.accent = match ? match[1] : root.fallbackAccent
    }
}

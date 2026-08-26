pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    readonly property color fallbackAccent: "#7aa2f7"
    property color accent: fallbackAccent

    property FileView colorsFile: FileView {
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

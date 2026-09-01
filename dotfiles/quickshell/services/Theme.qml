pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    readonly property color fallbackAccent: "#7aa2f7"
    readonly property color fallbackBg: "#000000"
    readonly property color fallbackFg: "#ffffff"
    property color accent: fallbackAccent
    property color bg: fallbackBg
    property color fg: fallbackFg

    // Plain string so `accentContrast` reliably re-binds — `accent.r/.g/.b`
    // grouped sub-properties don't reliably re-fire on reassignment.
    property string accentHex: fallbackAccent

    // Text/icon color for on top of `accent`, by relative luminance.
    // NOTE: never name a property `onXxx` — QML reserves that pattern for
    // signal handlers and silently mis-resolves reads, even with no signal
    // of that name declared and no error at load time.
    readonly property color accentContrast: root._contrastFor(root.accentHex)

    readonly property FileView colorsFile: FileView {
        path: Quickshell.env("HOME") + "/.local/state/my_theme/colors.css"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root._applyColors(text())
        onLoadFailed: {
            root.accent = root.fallbackAccent
            root.accentHex = root.fallbackAccent
            root.bg = root.fallbackBg
            root.fg = root.fallbackFg
        }
    }

    function _contrastFor(hex) {
        const h = hex.replace("#", "")
        const r = parseInt(h.substring(0, 2), 16) / 255.0
        const g = parseInt(h.substring(2, 4), 16) / 255.0
        const b = parseInt(h.substring(4, 6), 16) / 255.0
        const lum = 0.299 * r + 0.587 * g + 0.114 * b
        return lum > 0.6 ? "black" : "white"
    }

    function _applyColors(css) {
        const accentMatch = /@define-color\s+accent\s+(#[0-9a-fA-F]{6})/.exec(css)
        root.accentHex = accentMatch ? accentMatch[1] : root.fallbackAccent
        root.accent = root.accentHex
        const bgMatch = /@define-color\s+bg\s+(#[0-9a-fA-F]{6})/.exec(css)
        root.bg = bgMatch ? bgMatch[1] : root.fallbackBg
        const fgMatch = /@define-color\s+fg\s+(#[0-9a-fA-F]{6})/.exec(css)
        root.fg = fgMatch ? fgMatch[1] : root.fallbackFg
    }
}

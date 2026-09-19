pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    property bool open: false
    property var emoji: []

    // These three bottom-flush drawers all dock to the same screen edge —
    // opening one closes the other two so they can't stack/overlap.
    function toggle() { root.open ? root.hide() : root.show() }
    function show() {
        AppLauncherState.hide()
        ClipboardState.hide()
        root.open = true
    }
    function hide() { root.open = false }

    onOpenChanged: if (root.open) generator.running = true

    readonly property IpcHandler ipc: IpcHandler {
        target: "emojipicker"
        function toggle(): void { root.toggle() }
        function show(): void { root.show() }
        function hide(): void { root.hide() }
    }

    readonly property FileView emojiFile: FileView {
        path: Quickshell.env("HOME") + "/.cache/emoji/emoji.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.emoji = JSON.parse(text())
        onLoadFailed: root.emoji = []
    }

    // Self-skips instantly on a cache hit (see gen-emoji-data.sh), so
    // re-running on every open stays cheap; onExited reloads emojiFile so
    // the very first (cache-miss) run picks up the freshly-written file
    // instead of racing it.
    readonly property Process generator: Process {
        command: [Quickshell.env("HOME") + "/.local/bin/gen-emoji-data.sh"]
        onExited: root.emojiFile.reload()
    }

    Component.onCompleted: generator.running = true
}

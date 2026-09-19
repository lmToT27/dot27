pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    property bool open: false

    // These three bottom-flush drawers all dock to the same screen edge —
    // opening one closes the other two so they can't stack/overlap.
    function toggle() { root.open ? root.hide() : root.show() }
    function show() {
        AppLauncherState.hide()
        EmojiPickerState.hide()
        root.open = true
    }
    function hide() { root.open = false }

    readonly property IpcHandler ipc: IpcHandler {
        target: "clipboard"
        function toggle(): void { root.toggle() }
        function show(): void { root.show() }
        function hide(): void { root.hide() }
    }
}

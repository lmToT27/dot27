pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    property bool open: false

    // Opening the launcher closes every other panel it could visually
    // overlap or steal focus from.
    function toggle() { root.open ? root.hide() : root.show() }
    function show() {
        ClipboardState.hide()
        EmojiPickerState.hide()
        ThemePickerState.hide()
        WallpaperPickerState.hide()
        ScreenRecorderState.hide()
        WifiListState.hide()
        BluetoothListState.hide()
        root.open = true
    }
    function hide() { root.open = false }

    readonly property IpcHandler ipc: IpcHandler {
        target: "applauncher"
        function toggle(): void { root.toggle() }
        function show(): void { root.show() }
        function hide(): void { root.hide() }
    }
}

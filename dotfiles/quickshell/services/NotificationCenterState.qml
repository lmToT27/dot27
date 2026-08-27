pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Single source of truth for whether the Notification Center panel is
// open — mirrors ControlCenterState.qml, driven by the Mod+N niri keybind.
QtObject {
    id: root

    property bool open: false

    function toggle() { root.open = !root.open }
    // Alias of toggle(), named for the Mod+N keybind's IPC call site.
    function toggleVisibility() { root.toggle() }
    function show() { root.open = true }
    function hide() { root.open = false }

    readonly property IpcHandler ipc: IpcHandler {
        target: "notificationcenter"
        function toggle(): void { root.toggle() }
        function toggleVisibility(): void { root.toggle() }
        function show(): void { root.show() }
        function hide(): void { root.hide() }
    }
}

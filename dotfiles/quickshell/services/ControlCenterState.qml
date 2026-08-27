pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Single source of truth for whether the Control Center panel is open —
// driven by the Mod+M niri keybind via IPC (see `ipc` below).
QtObject {
    id: root

    property bool open: false

    function toggle() { root.open = !root.open }
    function show() { root.open = true }
    function hide() { root.open = false }

    // `quickshell ipc call controlcenter toggle` — lets the niri keybind
    // drive this without duplicating logic.
    readonly property IpcHandler ipc: IpcHandler {
        target: "controlcenter"
        function toggle(): void { root.toggle() }
        function show(): void { root.show() }
        function hide(): void { root.hide() }
    }
}

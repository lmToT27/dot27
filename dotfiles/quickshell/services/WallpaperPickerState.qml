pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    property bool open: false

    function toggle() { root.open = !root.open }
    function show() { root.open = true }
    function hide() { root.open = false }

    readonly property IpcHandler ipc: IpcHandler {
        target: "wallpaperpicker"
        function toggle(): void { root.toggle() }
        function show(): void { root.show() }
        function hide(): void { root.hide() }
    }
}

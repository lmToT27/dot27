pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    property bool active: false
    property string kind: "volume"

    function show(newKind) {
        root.kind = newKind
        root.active = true
        hideTimer.restart()
    }

    property Timer hideTimer: Timer {
        interval: 1500
        onTriggered: root.active = false
    }

    readonly property IpcHandler ipc: IpcHandler {
        target: "osd"
        function show(kind: string): void { root.show(kind) }
    }
}

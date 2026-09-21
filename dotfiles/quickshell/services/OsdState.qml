pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    property bool active: false
    property string kind: "volume"
    property int trigger: 0

    function show(newKind) {
        root.kind = newKind
        root.active = true
        root.trigger++
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

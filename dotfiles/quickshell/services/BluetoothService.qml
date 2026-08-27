pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    property string controllerAlias: ""
    property int connectedCount: 0
    property bool powered: true

    function togglePower() {
        Quickshell.execDetached(["bluetoothctl", "power", root.powered ? "off" : "on"])
    }

    // Long-running bluetoothctl prints a "[CHG] ..." line on every
    // controller/device change — event-driven, no polling.
    readonly property Process monitor: Process {
        command: ["bluetoothctl"]
        running: true
        stdout: SplitParser {
            onRead: line => {
                if (line.includes("Connected") || line.includes("Powered")) refresh.running = true
            }
        }
    }

    readonly property Process refresh: Process {
        command: ["sh", "-c", "bluetoothctl show | grep -E 'Alias|Powered'; bluetoothctl devices Connected"]
        stdout: StdioCollector {
            onStreamFinished: root._parseControllerInfo(text)
        }
    }

    function _parseControllerInfo(text) {
        const lines = text.split("\n").filter(l => l.length > 0)
        const aliasLine = lines.find(l => l.trim().startsWith("Alias:"))
        root.controllerAlias = aliasLine ? aliasLine.split(":").slice(1).join(":").trim() : ""
        const poweredLine = lines.find(l => l.trim().startsWith("Powered:"))
        if (poweredLine) root.powered = poweredLine.includes("yes")
        root.connectedCount = lines.filter(l => l.startsWith("Device")).length
    }

    Component.onCompleted: refresh.running = true
}

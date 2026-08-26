import QtQuick
import Quickshell.Io
import "../common"

HoverIcon {
    id: root

    property string controllerAlias: ""
    property int connectedCount: 0

    invertOnHover: false
    tooltip: true
    text: connectedCount > 0 ? "󰂱" : "󰂯"
    tooltipText: controllerAlias + "\n" + connectedCount + " connected"

    // Running bluetoothctl with no command keeps it attached and it prints
    // a "[CHG] ..." line on every controller/device change — event-driven.
    Process {
        id: monitor
        command: ["bluetoothctl"]
        running: true
        stdout: SplitParser {
            onRead: line => {
                if (line.includes("Connected") || line.includes("Powered")) refresh.running = true
            }
        }
    }

    Process {
        id: refresh
        command: ["sh", "-c", "bluetoothctl show | grep Alias; bluetoothctl devices Connected"]
        stdout: StdioCollector {
            onStreamFinished: root._parse(text)
        }
    }

    function _parse(text) {
        const lines = text.split("\n").filter(l => l.length > 0)
        const aliasLine = lines.find(l => l.trim().startsWith("Alias:"))
        root.controllerAlias = aliasLine ? aliasLine.split(":").slice(1).join(":").trim() : ""
        root.connectedCount = lines.filter(l => l.startsWith("Device")).length
    }

    Component.onCompleted: refresh.running = true
}

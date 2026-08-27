pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    readonly property var wifiIcons: ["󰤯", "󰤟", "󰤢", "󰤥", "󰤨"]

    property string kind: "disconnected"
    property int signalStrength: 0
    property string essid: ""
    property bool wifiRadioEnabled: true

    function toggleRadio() {
        Quickshell.execDetached(["nmcli", "radio", "wifi", root.wifiRadioEnabled ? "off" : "on"])
    }

    // nmcli monitor streams a line on every NM state change — event-driven,
    // no Timer poll.
    readonly property Process monitor: Process {
        command: ["nmcli", "monitor"]
        running: true
        stdout: SplitParser {
            onRead: () => {
                statusQuery.running = true
                radioQuery.running = true
            }
        }
    }

    readonly property Process statusQuery: Process {
        command: ["nmcli", "-t", "-f", "DEVICE,TYPE,STATE,CONNECTION", "device"]
        stdout: StdioCollector {
            onStreamFinished: root._parseStatus(text)
        }
    }

    readonly property Process activeWifiQuery: Process {
        command: ["nmcli", "-t", "-f", "active,signal,ssid", "dev", "wifi"]
        stdout: StdioCollector {
            onStreamFinished: root._parseActiveWifi(text)
        }
    }

    readonly property Process radioQuery: Process {
        command: ["nmcli", "radio", "wifi"]
        stdout: StdioCollector {
            onStreamFinished: root.wifiRadioEnabled = text.trim() === "enabled"
        }
    }

    function _parseStatus(text) {
        const line = text.split("\n").find(l => /:(wifi|ethernet):connected:/.test(l))
        if (!line) {
            root.kind = "disconnected"
            return
        }
        const type = line.split(":")[1]
        root.kind = type
        if (type === "wifi") activeWifiQuery.running = true
    }

    function _parseActiveWifi(text) {
        const line = text.split("\n").find(l => l.startsWith("yes:"))
        if (!line) return
        const parts = line.split(":")
        root.signalStrength = parseInt(parts[1]) || 0
        root.essid = parts[2] || ""
    }

    Component.onCompleted: {
        statusQuery.running = true
        radioQuery.running = true
    }
}

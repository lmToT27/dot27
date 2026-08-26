import QtQuick
import Quickshell.Io
import "../common"

HoverIcon {
    id: root

    readonly property var wifiIcons: ["󰤯", "󰤟", "󰤢", "󰤥", "󰤨"]

    property string kind: "disconnected"
    property int signalStrength: 0
    property string essid: ""

    invertOnHover: false
    tooltip: true
    text: kind === "ethernet" ? "󰈀"
        : kind === "wifi" ? wifiIcons[Math.min(wifiIcons.length - 1, Math.floor(signalStrength / 20))]
        : "󰤮"
    tooltipText: kind === "wifi" ? essid
        : kind === "ethernet" ? "Ethernet"
        : "Disconnected"

    // nmcli monitor streams a line on every NM state change, so refreshes
    // are event-driven instead of a Timer poll.
    Process {
        id: monitor
        command: ["nmcli", "monitor"]
        running: true
        stdout: SplitParser {
            onRead: () => statusQuery.running = true
        }
    }

    Process {
        id: statusQuery
        command: ["nmcli", "-t", "-f", "DEVICE,TYPE,STATE,CONNECTION", "device"]
        stdout: StdioCollector {
            onStreamFinished: root._parseStatus(text)
        }
    }

    Process {
        id: wifiQuery
        command: ["nmcli", "-t", "-f", "active,signal,ssid", "dev", "wifi"]
        stdout: StdioCollector {
            onStreamFinished: root._parseWifi(text)
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
        if (type === "wifi") wifiQuery.running = true
    }

    function _parseWifi(text) {
        const line = text.split("\n").find(l => l.startsWith("yes:"))
        if (!line) return
        const parts = line.split(":")
        root.signalStrength = parseInt(parts[1]) || 0
        root.essid = parts[2] || ""
    }

    Component.onCompleted: statusQuery.running = true
}

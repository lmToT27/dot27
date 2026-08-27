import QtQuick
import Quickshell.Io
import "../common"
import "../../config"
import "../../services"

HoverIcon {
    id: root

    readonly property var icons: ["󰂎", "󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"]

    property string batteryName: "BAT0"
    property int capacity: 100
    property string status: "Unknown"
    property real energyNow: 0
    property real energyFull: 0
    property real powerNow: 0

    readonly property bool isCharging: status === "Charging"
    readonly property bool isPlugged: status === "Full" || status === "Not charging"
    readonly property bool isCritical: capacity <= 15 && !isCharging
    readonly property bool isWarning: capacity <= 30 && !isCharging && !isCritical

    // energy_now/energy_full/power_now are in µWh/µW, so their ratio is
    // already hours — no unit conversion needed.
    readonly property real estimateHours: powerNow > 0
        ? (isCharging ? (energyFull - energyNow) / powerNow : energyNow / powerNow)
        : 0
    readonly property string estimateText: {
        if (estimateHours <= 0) return ""
        const h = Math.floor(estimateHours)
        const m = Math.round((estimateHours - h) * 60)
        const duration = h > 0 ? (h + "h " + m + "m") : (m + "m")
        return isCharging ? ("~" + duration + " until full") : ("~" + duration + " remaining")
    }

    invertOnHover: false
    blinking: isCritical
    tooltip: true
    tooltipText: status + " — " + capacity + "%" + (estimateText ? " • " + estimateText : "")
    textColor: isCritical ? Appearance.critical
        : isWarning ? Appearance.warning
        : isCharging ? Appearance.charging
        : Theme.accent
    text: isCharging ? ("󰂄 " + capacity + "%")
        : isPlugged ? (" " + capacity + "%")
        : (icons[Math.min(icons.length - 1, Math.round(capacity / 10))] + " " + capacity + "%")

    // One-shot discovery of the real battery name (BAT0/BAT1/...).
    Process {
        id: discover
        command: ["sh", "-c", "ls /sys/class/power_supply | grep -m1 BAT"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const name = text.trim()
                if (name.length > 0) root.batteryName = name
            }
        }
    }

    // sysfs power_supply attributes don't support inotify, so a Timer poll
    // is the only way to see updates (same reasoning as /proc/uptime in
    // UptimeService.qml). uevent bundles every field needed per read.
    FileView {
        id: ueventFile
        path: "/sys/class/power_supply/" + root.batteryName + "/uevent"
        onLoaded: {
            const fields = {}
            for (const line of text().split("\n")) {
                const eq = line.indexOf("=")
                if (eq < 0) continue
                fields[line.slice(0, eq)] = line.slice(eq + 1)
            }
            if ("POWER_SUPPLY_STATUS" in fields) root.status = fields.POWER_SUPPLY_STATUS
            if ("POWER_SUPPLY_CAPACITY" in fields) root.capacity = parseInt(fields.POWER_SUPPLY_CAPACITY) || root.capacity
            if ("POWER_SUPPLY_ENERGY_NOW" in fields) root.energyNow = parseFloat(fields.POWER_SUPPLY_ENERGY_NOW) || 0
            if ("POWER_SUPPLY_ENERGY_FULL" in fields) root.energyFull = parseFloat(fields.POWER_SUPPLY_ENERGY_FULL) || 0
            if ("POWER_SUPPLY_POWER_NOW" in fields) root.powerNow = parseFloat(fields.POWER_SUPPLY_POWER_NOW) || 0
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: false
        onTriggered: ueventFile.reload()
    }
}

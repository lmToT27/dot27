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

    readonly property bool isCharging: status === "Charging"
    readonly property bool isPlugged: status === "Full" || status === "Not charging"
    readonly property bool isCritical: capacity <= 15 && !isCharging
    readonly property bool isWarning: capacity <= 30 && !isCharging && !isCritical

    invertOnHover: false
    blinking: isCritical
    tooltip: true
    tooltipText: status + " — " + capacity + "%"
    textColor: isCritical ? Appearance.critical
        : isWarning ? Appearance.warning
        : isCharging ? Appearance.charging
        : Theme.accent
    text: isCharging ? ("󰂄 " + capacity + "%")
        : isPlugged ? (" " + capacity + "%")
        : (icons[Math.min(icons.length - 1, Math.round(capacity / 10))] + " " + capacity + "%")

    // One-shot discovery of the real battery name (BAT0/BAT1/...), then the
    // two FileViews below watch sysfs directly — no polling.
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

    FileView {
        id: capacityFile
        path: "/sys/class/power_supply/" + root.batteryName + "/capacity"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.capacity = parseInt(text()) || root.capacity
    }

    FileView {
        id: statusFile
        path: "/sys/class/power_supply/" + root.batteryName + "/status"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.status = text().trim()
    }
}

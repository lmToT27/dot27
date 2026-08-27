pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// /proc/uptime doesn't emit inotify change events, so there's no
// event-driven way to watch it — a minute-aligned Timer instead, matching
// the HH:MM display granularity.
QtObject {
    id: root

    property int seconds: 0
    readonly property string formatted: {
        const h = Math.floor(root.seconds / 3600)
        const m = Math.floor((root.seconds % 3600) / 60)
        return String(h).padStart(2, "0") + ":" + String(m).padStart(2, "0")
    }

    readonly property FileView uptimeFile: FileView {
        path: "/proc/uptime"
        onLoaded: {
            const secs = parseFloat(text())
            root.seconds = isNaN(secs) ? 0 : Math.floor(secs)
        }
    }

    readonly property Timer tick: Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: uptimeFile.reload()
    }
}

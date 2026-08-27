pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    property string deviceName: "amdgpu_bl1"
    property int raw: 0
    property int max: 1
    readonly property int percent: max > 0 ? Math.round((raw / max) * 100) : 0

    function setPercent(pct) {
        Quickshell.execDetached(["brightnessctl", "--class=backlight", "set", pct + "%"])
    }

    // One-shot discovery of the real backlight device name (in case it's
    // not amdgpu_bl1); the FileViews below then watch sysfs directly.
    readonly property Process discover: Process {
        command: ["sh", "-c", "ls /sys/class/backlight | head -n1"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const name = text.trim()
                if (name.length > 0) root.deviceName = name
            }
        }
    }

    readonly property FileView brightnessFile: FileView {
        path: "/sys/class/backlight/" + root.deviceName + "/brightness"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.raw = parseInt(text()) || 0
    }

    readonly property FileView maxBrightnessFile: FileView {
        path: "/sys/class/backlight/" + root.deviceName + "/max_brightness"
        onLoaded: root.max = parseInt(text()) || 1
    }
}

import QtQuick
import Quickshell
import Quickshell.Io
import "../../config"
import "../../services"

Text {
    id: root

    // No media loaded means no audio to visualize — stay hidden and keep
    // cava.sh from running (and skip Row layout space) until there is one.
    readonly property bool active: Mpris.hasMedia

    visible: active
    color: Theme.accent
    font.family: Appearance.fontFamily
    font.bold: true
    font.letterSpacing: -2
    transform: Translate { x: -1; y: 2 }

    onActiveChanged: cava.running = active
    Component.onCompleted: cava.running = active

    Process {
        id: cava
        command: [Quickshell.env("HOME") + "/.local/bin/cava.sh"]
        stdout: SplitParser {
            onRead: line => root.text = line
        }
        // Respawn cava.sh if it dies, but only while media is still active.
        onExited: if (root.active) restartDelay.start()
    }

    Timer {
        id: restartDelay
        interval: 1000
        repeat: false
        onTriggered: cava.running = true
    }
}

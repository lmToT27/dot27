import QtQuick
import Quickshell
import Quickshell.Io
import "../../config"
import "../../services"

Text {
    id: root

    color: Theme.accent
    font.family: Appearance.fontFamily
    font.bold: true
    font.letterSpacing: -2
    transform: Translate { x: -1; y: 2 }

    Process {
        id: cava
        command: [Quickshell.env("HOME") + "/.local/bin/cava.sh"]
        running: true
        stdout: SplitParser {
            onRead: line => root.text = line
        }
        onExited: restartDelay.start()
    }

    // Mirrors waybar's restart-interval: 1 — respawn cava.sh if it dies.
    Timer {
        id: restartDelay
        interval: 1000
        repeat: false
        onTriggered: cava.running = true
    }
}

import "../common"
import "../../config"
import "../../services"

// Only appears while recording: shows elapsed MM:SS inside a thin red
// border, blinking continuously like the iOS/macOS status-bar indicator.
// Clicking it stops the capture.
HoverIcon {
    id: root

    readonly property int elapsedSeconds: ScreenRecorder.elapsedSeconds
    readonly property string elapsed: {
        const m = Math.floor(elapsedSeconds / 60)
        const s = elapsedSeconds % 60
        return (m < 10 ? "0" : "") + m + ":" + (s < 10 ? "0" : "") + s
    }

    visible: ScreenRecorder.recording
    text: root.elapsed
    fontSize: Appearance.fontSize - 2
    textColor: Theme.accent
    borderColor: Theme.accent
    borderWidth: 2
    invertOnHover: false
    blinking: true
    tooltip: true
    tooltipText: "Screen Recording — Press to stop"

    onClicked: ScreenRecorder.stop()
}

import Quickshell
import Quickshell.Io
import "../common"

HoverIcon {
    id: root

    property string status: "Stopped"
    property string mediaTitle: ""
    property string mediaArtist: ""

    readonly property bool hasMedia: status === "Playing" || status === "Paused"
    readonly property string label: mediaTitle + (mediaArtist ? " — " + mediaArtist : "")

    text: hasMedia
        ? ((status === "Playing" ? "  " : " ") + (label.length > 20 ? label.slice(0, 20) + "…" : label))
        : " No Media"
    tooltip: hasMedia
    tooltipText: label
    onClicked: Quickshell.execDetached(["playerctl", "play-pause"])

    function applyLine(line) {
        const parts = line.split("\t")
        if (parts.length < 3 || parts[0].length === 0) {
            root.status = "Stopped"
            root.mediaTitle = ""
            root.mediaArtist = ""
        } else {
            root.status = parts[0]
            root.mediaTitle = parts[1]
            root.mediaArtist = parts[2]
        }
    }

    // One-shot initial read: playerctl --follow only emits a line once the
    // state actually *changes*, not the current state at startup.
    Process {
        command: ["playerctl", "--format", "{{status}}\t{{title}}\t{{artist}}", "metadata"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.applyLine(text.trim())
        }
    }

    // Event-driven: blocks and only prints when playback status or metadata
    // actually changes, so no Timer polling is needed.
    Process {
        command: ["playerctl", "--follow", "--format", "{{status}}\t{{title}}\t{{artist}}", "metadata"]
        running: true
        stdout: SplitParser {
            onRead: line => root.applyLine(line)
        }
    }
}

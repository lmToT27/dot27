pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Tracks every MPRIS player via `playerctl -a`, but only ever exposes ONE
// as "the" player: the first Playing one, falling back to the first
// Paused one, so a stale/backgrounded player (e.g. a browser tab with a
// muted video) can't outrank whatever's actually making sound.
QtObject {
    id: root

    property string status: "Stopped"
    property string title: ""
    property string artist: ""
    property string artUrl: ""
    property string playerName: ""
    property real position: 0
    property real length: 0

    readonly property bool hasMedia: status === "Playing" || status === "Paused"

    // name -> {status, title, artist, artUrl, length}. Rebuilt wholesale by
    // fullSync, patched incrementally by the --follow stream in between.
    property var players: ({})

    function playPause() { if (root.playerName) Quickshell.execDetached(["playerctl", "-p", root.playerName, "play-pause"]) }
    function next() { if (root.playerName) Quickshell.execDetached(["playerctl", "-p", root.playerName, "next"]) }
    function previous() { if (root.playerName) Quickshell.execDetached(["playerctl", "-p", root.playerName, "previous"]) }

    readonly property string format: "{{playerName}}\t{{status}}\t{{title}}\t{{artist}}\t{{mpris:artUrl}}\t{{mpris:length}}"

    function pickActive() {
        let playing = ""
        let paused = ""
        for (const name in root.players) {
            const p = root.players[name]
            if (p.status === "Playing" && !playing) playing = name
            else if (p.status === "Paused" && !paused) paused = name
        }
        const activeName = playing || paused

        if (!activeName) {
            root.playerName = ""
            root.status = "Stopped"
            root.title = ""
            root.artist = ""
            root.artUrl = ""
            root.length = 0
            root.position = 0
            return
        }

        const p = root.players[activeName]
        root.playerName = activeName
        root.status = p.status
        root.title = p.title
        root.artist = p.artist
        root.artUrl = p.artUrl
        root.length = p.length
        positionQuery.running = true
    }

    // One line per player: playerName\tstatus\ttitle\tartist\tartUrl\tlength
    function applyLine(line) {
        const parts = line.split("\t")
        if (parts.length < 2 || !parts[0]) return
        root.players[parts[0]] = {
            status: parts[1] || "Stopped",
            title: parts[2] || "",
            artist: parts[3] || "",
            artUrl: parts[4] || "",
            length: (parseFloat(parts[5]) || 0) / 1000000
        }
        root.pickActive()
    }

    // From-scratch rebuild of `players` — drops a player that quit without
    // --follow emitting a removal line (playerctl doesn't reliably do so).
    function fullSync(output) {
        const next = {}
        const lines = output.split("\n")
        for (const line of lines) {
            const parts = line.split("\t")
            if (parts.length < 2 || !parts[0]) continue
            next[parts[0]] = {
                status: parts[1] || "Stopped",
                title: parts[2] || "",
                artist: parts[3] || "",
                artUrl: parts[4] || "",
                length: (parseFloat(parts[5]) || 0) / 1000000
            }
        }
        root.players = next
        root.pickActive()
    }

    readonly property Process initialQuery: Process {
        command: ["playerctl", "-a", "--format", root.format, "metadata"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.fullSync(text.trim())
        }
    }

    // Event-driven for the common case: play/pause/skip/metadata change on
    // an already-known player.
    readonly property Process follow: Process {
        command: ["playerctl", "-a", "--follow", "--format", root.format, "metadata"]
        running: true
        stdout: SplitParser {
            onRead: line => root.applyLine(line)
        }
    }

    // Deliberate poll: reconciles players that disappeared without a clean
    // --follow removal event (e.g. a browser tab closed mid-track).
    readonly property Process resync: Process {
        command: ["playerctl", "-a", "--format", root.format, "metadata"]
        stdout: StdioCollector {
            onStreamFinished: root.fullSync(text.trim())
        }
    }

    readonly property Timer resyncTimer: Timer {
        interval: 4000
        repeat: true
        running: true
        onTriggered: resync.running = true
    }

    readonly property Process positionQuery: Process {
        command: ["playerctl", "-p", root.playerName, "position"]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = parseFloat(text.trim())
                if (!isNaN(p)) root.position = p
            }
        }
    }

    // Deliberate poll: no event reports "1 second elapsed" during
    // playback; the UI smooths the jump with a Behavior on the progress bar.
    readonly property Timer positionTimer: Timer {
        interval: 1000
        repeat: true
        running: root.status === "Playing"
        onTriggered: positionQuery.running = true
    }
}

pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    readonly property bool recording: proc.running
    readonly property string outputDir: Quickshell.env("HOME") + "/Videos"
    property string currentFile: ""
    property int elapsedSeconds: 0

    function start() {
        if (proc.running) return
        root.elapsedSeconds = 0
        root.currentFile = root.outputDir + "/screencast_"
            + Qt.formatDateTime(new Date(), "yyyyMMdd_HHmmss") + ".mp4"
        proc.command = ["sh", "-c",
            "mkdir -p '" + root.outputDir + "'"
            + " && output=$(niri msg --json focused-output | jq -r .name)"
            + " && exec wf-recorder -o \"$output\" -f '" + root.currentFile + "'"
        ]
        proc.running = true
    }

    // running: false sends SIGTERM, which wf-recorder catches to finalize
    // the mp4 container cleanly — no kill.
    function stop() {
        proc.running = false
    }

    function toggle() {
        if (root.recording) root.stop(); else root.start()
    }

    // Deliberate poll: no event reports "1 more second recorded".
    readonly property Timer elapsedTimer: Timer {
        interval: 1000
        repeat: true
        running: root.recording
        onTriggered: root.elapsedSeconds += 1
    }

    readonly property Process proc: Process {
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0 && root.currentFile.length > 0) {
                Quickshell.execDetached(["notify-send", "-a", "Screen Recorder",
                    "Screen recording saved", root.currentFile])
            }
            root.currentFile = ""
        }
    }

    // `quickshell ipc call recorder toggle` — drives recording from a niri
    // keybind without duplicating this logic.
    readonly property IpcHandler ipc: IpcHandler {
        target: "recorder"
        function toggle(): void { root.toggle() }
        function start(): void { root.start() }
        function stop(): void { root.stop() }
    }
}

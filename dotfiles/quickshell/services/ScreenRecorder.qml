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

    function _prelude() {
        root.elapsedSeconds = 0
        root.currentFile = root.outputDir + "/screencast_"
            + Qt.formatDateTime(new Date(), "yyyyMMdd_HHmmss") + ".mp4"
        return "mkdir -p '" + root.outputDir + "'"
            + " && output=$(niri msg --json focused-output | jq -r .name)"
    }

    readonly property string _encodeFlags: "--no-hw --codec avc"

    function startNoAudio() {
        if (proc.running) return
        proc.command = ["sh", "-c",
            root._prelude()
            + " && exec wl-screenrec -o \"$output\" " + root._encodeFlags
            + " -f '" + root.currentFile + "'"
        ]
        proc.running = true
    }

    function startMicAndAudio() {
        if (proc.running) return
        proc.command = ["sh", "-c",
            root._prelude()
            + " && exec wl-screenrec -o \"$output\" " + root._encodeFlags
            + " --audio -f '" + root.currentFile + "'"
        ]
        proc.running = true
    }

    function startSystemAudio() {
        if (proc.running) return
        proc.command = ["sh", "-c",
            root._prelude()
            + " && sink=$(pw-cli info $(wpctl inspect @DEFAULT_SINK@ | head -1"
            + " | grep -oP 'id \\K[0-9]+') | grep -oP 'node\\.name = \"\\K[^\"]+')"
            + " && exec wl-screenrec -o \"$output\" " + root._encodeFlags
            + " --audio --audio-device \"${sink}.monitor\" -f '" + root.currentFile + "'"
        ]
        proc.running = true
    }

    function stop() {
        proc.running = false
    }

    function toggle() {
        if (root.recording) root.stop(); else root.startNoAudio()
    }

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

    readonly property IpcHandler ipc: IpcHandler {
        target: "recorder"
        function toggle(): void { root.toggle() }
        function start(): void { root.startNoAudio() }
        function startMicAndAudio(): void { root.startMicAndAudio() }
        function startSystemAudio(): void { root.startSystemAudio() }
        function stop(): void { root.stop() }
    }
}

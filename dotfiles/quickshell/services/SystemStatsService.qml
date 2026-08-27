pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Real RAM/CPU/GPU usage. Only polls while `active` is set (see the
// Binding in SystemMonitor.qml) — nvidia-smi in particular is too costly
// to run in the background while the panel is closed.
QtObject {
    id: root

    property bool active: false

    property real ramPercent: 0
    property real cpuPercent: 0
    property real gpuPercent: 0

    // {idle, total} from the previous /proc/stat sample — CPU usage is a
    // delta between two samples' cumulative jiffies, not a snapshot.
    // Deliberately never reset when `active` goes false, so the first
    // sample after reopening the panel still has a prior point to diff
    // against (just averaged over however long it's been closed).
    property var _prevCpu: null

    function _parseMeminfo(text) {
        const total = /MemTotal:\s+(\d+)/.exec(text)
        const avail = /MemAvailable:\s+(\d+)/.exec(text)
        if (!total || !avail) return
        const t = parseFloat(total[1])
        const a = parseFloat(avail[1])
        if (t > 0) root.ramPercent = ((t - a) / t) * 100
    }

    function _parseCpuStat(text) {
        const line = text.split("\n").find(l => l.startsWith("cpu "))
        if (!line) return
        const fields = line.trim().split(/\s+/).slice(1).map(Number)
        // user nice system idle iowait irq softirq steal ...
        const idle = fields[3] + (fields[4] || 0)
        const total = fields.reduce((a, b) => a + b, 0)
        if (root._prevCpu) {
            const dIdle = idle - root._prevCpu.idle
            const dTotal = total - root._prevCpu.total
            if (dTotal > 0) root.cpuPercent = Math.max(0, Math.min(100, (1 - dIdle / dTotal) * 100))
        }
        root._prevCpu = { idle: idle, total: total }
    }

    function _parseGpu(text) {
        const v = parseFloat(text.trim())
        if (!isNaN(v)) root.gpuPercent = v
    }

    readonly property Process ramQuery: Process {
        command: ["cat", "/proc/meminfo"]
        stdout: StdioCollector { onStreamFinished: root._parseMeminfo(text) }
    }

    readonly property Process cpuQuery: Process {
        command: ["cat", "/proc/stat"]
        stdout: StdioCollector { onStreamFinished: root._parseCpuStat(text) }
    }

    // Discrete NVIDIA GPU (PRIME offload) is the one worth watching for
    // load; the AMD iGPU handles display compositing regardless.
    readonly property Process gpuQuery: Process {
        command: ["nvidia-smi", "--query-gpu=utilization.gpu", "--format=csv,noheader,nounits"]
        stdout: StdioCollector { onStreamFinished: root._parseGpu(text) }
    }

    readonly property Timer pollTimer: Timer {
        interval: 2000
        repeat: true
        running: root.active
        triggeredOnStart: true
        onTriggered: {
            ramQuery.running = true
            cpuQuery.running = true
            gpuQuery.running = true
        }
    }
}

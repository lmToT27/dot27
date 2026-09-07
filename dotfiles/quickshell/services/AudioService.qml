pragma Singleton
import QtQuick
import Quickshell.Services.Pipewire

QtObject {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool ready: sink !== null && sink.audio !== null
    readonly property int volume: ready ? Math.round(sink.audio.volume * 100) : 0
    readonly property bool muted: ready ? sink.audio.muted : false

    readonly property var source: Pipewire.defaultAudioSource
    readonly property bool micReady: source !== null && source.audio !== null
    readonly property bool micMuted: micReady ? source.audio.muted : false

    function setVolume(pct) {
        if (ready) sink.audio.volume = Math.max(0, Math.min(100, pct)) / 100
    }

    function toggleMute() {
        if (ready) sink.audio.muted = !sink.audio.muted
    }

    function toggleMicMute() {
        if (micReady) source.audio.muted = !source.audio.muted
    }

    // Keeps the default sink/source's audio properties actively subscribed/updated.
    readonly property PwObjectTracker tracker: PwObjectTracker {
        objects: (root.sink ? [root.sink] : []).concat(root.source ? [root.source] : [])
    }
}

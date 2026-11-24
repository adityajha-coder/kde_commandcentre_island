import Quickshell
import Quickshell.Services.Pipewire
import QtQuick

// Default output volume via PipeWire.
Scope {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool ready: sink !== null && sink !== undefined && sink.audio !== null && sink.audio !== undefined
    readonly property real volume: ready ? sink.audio.volume : 0
    readonly property bool muted: ready ? sink.audio.muted : false

    function setVolume(v) {
        if (!ready) return
        sink.audio.muted = false
        sink.audio.volume = Math.max(0, Math.min(1, v))
    }

    function toggleMute() {
        if (!ready) return
        sink.audio.muted = !sink.audio.muted
    }

    PwObjectTracker {
        objects: root.sink ? [root.sink] : []
    }
}

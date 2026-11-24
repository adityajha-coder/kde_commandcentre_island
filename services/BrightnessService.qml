import Quickshell
import Quickshell.Io
import QtQuick

// Screen brightness. Prefers KDE's PowerDevil D-Bus API, falls back to brightnessctl.
Scope {
    id: root

    property bool available: false
    property real level: 0.5      // 0..1
    property int maxValue: 100
    property string backend: ""   // "powerdevil" | "brightnessctl"
    property real pending: -1

    readonly property var pdCall: [
        "busctl", "--user", "call",
        "org.kde.Solid.PowerManagement",
        "/org/kde/Solid/PowerManagement/Actions/BrightnessControl",
        "org.kde.Solid.PowerManagement.Actions.BrightnessControl"
    ]

    function refresh() { pdMax.running = true }

    function setLevel(v) {
        level = Math.max(0.02, Math.min(1, v))
        pending = level
        if (!throttle.running) throttle.start()
    }

    function flush() {
        if (pending < 0) return
        const target = pending
        pending = -1
        if (backend === "powerdevil") {
            Quickshell.execDetached(pdCall.concat(["setBrightness", "i", String(Math.round(target * maxValue))]))
        } else if (backend === "brightnessctl") {
            Quickshell.execDetached(["brightnessctl", "-q", "set", Math.round(target * 100) + "%"])
        }
    }

    // Sends at most one change every 70 ms while dragging the slider.
    Timer {
        id: throttle
        interval: 70
        onTriggered: root.flush()
    }

    Process {
        id: pdMax
        command: root.pdCall.concat(["brightnessMax"])
        stdout: StdioCollector {
            onStreamFinished: {
                const m = text.match(/i\s+(\d+)/)
                if (m && parseInt(m[1]) > 0) {
                    root.maxValue = parseInt(m[1])
                    root.backend = "powerdevil"
                    root.available = true
                    pdNow.running = true
                } else {
                    bctl.running = true
                }
            }
        }
    }

    Process {
        id: pdNow
        command: root.pdCall.concat(["brightness"])
        stdout: StdioCollector {
            onStreamFinished: {
                const m = text.match(/i\s+(\d+)/)
                if (m && root.maxValue > 0) root.level = Math.max(0.02, Math.min(1, parseInt(m[1]) / root.maxValue))
            }
        }
    }

    Process {
        id: bctl
        command: ["brightnessctl", "-m"]
        stdout: StdioCollector {
            onStreamFinished: {
                // e.g. intel_backlight,backlight,2000,50%,4000
                const parts = text.trim().split(",")
                if (parts.length >= 5 && parseInt(parts[4]) > 0) {
                    root.maxValue = parseInt(parts[4])
                    root.level = Math.max(0.02, Math.min(1, parseInt(parts[2]) / root.maxValue))
                    root.backend = "brightnessctl"
                    root.available = true
                } else {
                    root.available = false
                }
            }
        }
    }
}

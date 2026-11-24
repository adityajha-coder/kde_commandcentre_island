import Quickshell
import Quickshell.Io
import QtQuick

// Reading mode: constant warm Night Light (see scripts/reading-mode.sh).
Scope {
    id: root

    property bool active: false
    property int temperature: 3600
    property int _pendingTemp: -1

    signal temperatureCommitted(int kelvin)

    readonly property string script: Quickshell.shellDir + "/scripts/reading-mode.sh"

    function refresh() { status.running = true }

    function toggle() {
        active = !active
        _pendingTemp = -1
        throttle.stop()
        Quickshell.execDetached(active ? ["sh", script, "on", String(temperature)] : ["sh", script, "off"])
    }

    function setTemperature(kelvin, autoEnable) {
        const clamped = Math.max(1000, Math.min(6500, Math.round(kelvin / 50) * 50))
        temperature = clamped
        if (autoEnable && !active) active = true
        temperatureCommitted(clamped)
        if (active) {
            _pendingTemp = clamped
            if (!throttle.running) {
                flushTemp()
                throttle.start()
            }
        }
    }

    function flushTemp() {
        if (_pendingTemp < 0 || !active) return
        const target = _pendingTemp
        _pendingTemp = -1
        Quickshell.execDetached(["sh", script, "on", String(target)])
    }

    Timer {
        id: throttle
        interval: 120
        onTriggered: root.flushTemp()
    }

    Process {
        id: status
        command: ["sh", root.script, "status"]
        stdout: StdioCollector {
            onStreamFinished: root.active = text.trim() === "on"
        }
    }
}

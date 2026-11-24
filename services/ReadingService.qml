import Quickshell
import Quickshell.Io
import QtQuick

// Reading mode: constant warm Night Light (see scripts/reading-mode.sh).
Scope {
    id: root

    property bool active: false
    property int temperature: 3600

    readonly property string script: Quickshell.shellDir + "/scripts/reading-mode.sh"

    function refresh() { status.running = true }

    function toggle() {
        active = !active
        Quickshell.execDetached(active ? ["sh", script, "on", String(temperature)] : ["sh", script, "off"])
    }

    Process {
        id: status
        command: ["sh", root.script, "status"]
        stdout: StdioCollector {
            onStreamFinished: root.active = text.trim() === "on"
        }
    }
}

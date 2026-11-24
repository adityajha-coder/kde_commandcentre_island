import Quickshell
import Quickshell.Io
import QtQuick

// Bluetooth power state and the first connected device, via bluetoothctl.
Scope {
    id: root

    property bool available: false
    property bool enabled: false
    property string device: ""

    function refresh() { show.running = true }

    function toggle() {
        enabled = !enabled
        if (!enabled) device = ""
        Quickshell.execDetached(["sh", "-c",
            enabled ? "rfkill unblock bluetooth 2>/dev/null; bluetoothctl power on"
                    : "bluetoothctl power off"])
        settle.restart()
    }

    Timer {
        id: settle
        interval: 1800
        onTriggered: root.refresh()
    }

    Process {
        id: show
        command: ["bluetoothctl", "show"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.available = text.indexOf("Controller") >= 0
                root.enabled = /Powered:\s*yes/.test(text)
                if (root.enabled) devices.running = true
                else root.device = ""
            }
        }
    }

    Process {
        id: devices
        command: ["bluetoothctl", "devices", "Connected"]
        stdout: StdioCollector {
            onStreamFinished: {
                // "Device AA:BB:CC:DD:EE:FF Some Name"
                const first = text.split("\n").filter(l => l.startsWith("Device "))[0]
                root.device = first ? first.split(" ").slice(2).join(" ") : ""
            }
        }
    }
}

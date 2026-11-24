import Quickshell
import Quickshell.Io
import QtQuick

// Wi-Fi radio state and current network name via NetworkManager (nmcli).
Scope {
    id: root

    property bool available: true
    property bool enabled: false
    property string ssid: ""

    function refresh() { radio.running = true }

    function toggle() {
        enabled = !enabled
        if (!enabled) ssid = ""
        Quickshell.execDetached(["nmcli", "radio", "wifi", enabled ? "on" : "off"])
        settle.restart()
    }

    Timer {
        id: settle
        interval: 1800
        onTriggered: root.refresh()
    }

    Process {
        id: radio
        command: ["nmcli", "radio", "wifi"]
        stdout: StdioCollector {
            onStreamFinished: {
                const state = text.trim()
                root.available = state !== ""
                root.enabled = state === "enabled"
                if (root.enabled) ssidProc.running = true
                else root.ssid = ""
            }
        }
    }

    Process {
        id: ssidProc
        command: ["nmcli", "-t", "-f", "ACTIVE,SSID", "dev", "wifi", "list", "--rescan", "no"]
        stdout: StdioCollector {
            onStreamFinished: {
                let name = ""
                const lines = text.split("\n")
                for (let i = 0; i < lines.length; i++) {
                    if (lines[i].startsWith("yes:")) {
                        name = lines[i].slice(4).replace(/\\:/g, ":")
                        break
                    }
                }
                root.ssid = name
            }
        }
    }
}

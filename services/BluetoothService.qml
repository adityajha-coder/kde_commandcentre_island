import Quickshell
import Quickshell.Io
import QtQuick

// Bluetooth power state, paired devices list, connect/disconnect, and battery via bluetoothctl.
Scope {
    id: root

    property bool available: false
    property bool enabled: false
    property string device: ""
    property int battery: -1

    property var devicesList: []
    property bool scanning: false
    property string busyMac: ""
    property string busyAction: ""
    property string actionError: ""
    property string errorMac: ""
    property bool errorKeyMissing: false

    property string _activeMac: ""

    function refresh() { show.running = true }

    function toggle() {
        enabled = !enabled
        if (!enabled) {
            device = ""
            battery = -1
            devicesList = []
        }
        Quickshell.execDetached(["sh", "-c",
            enabled ? "rfkill unblock bluetooth 2>/dev/null; bluetoothctl power on"
                    : "bluetoothctl power off"])
        settle.restart()
    }

    function loadDevices() {
        if (!enabled) {
            devicesList = []
            scanning = false
            return
        }
        scanning = true
        detailProc.running = true
    }

    function toggleDevice(dev) {
        if (busyMac !== "") return
        actionError = ""
        errorMac = ""
        errorKeyMissing = false
        busyMac = dev.mac
        busyAction = dev.connected ? "Disconnecting…" : "Connecting…"
        const verb = dev.connected ? "disconnect" : "connect"
        actionProc.exec(["bluetoothctl", verb, dev.mac])
    }

    function forgetDevice(mac) {
        if (busyMac !== "") return
        actionError = ""
        errorMac = ""
        errorKeyMissing = false
        busyMac = mac
        busyAction = "Removing…"
        actionProc.exec(["bluetoothctl", "remove", mac])
    }

    function openSettings() {
        Quickshell.execDetached(["kcmshell6", "kcm_bluetooth"])
    }

    function kindFromIcon(iconName) {
        if (!iconName || iconName === "") return "Device"
        const n = iconName.toLowerCase()
        if (n.indexOf("audio") >= 0 || n.indexOf("headset") >= 0 || n.indexOf("headphone") >= 0) return "Audio"
        if (n.indexOf("phone") >= 0) return "Phone"
        if (n.indexOf("keyboard") >= 0) return "Keyboard"
        if (n.indexOf("mouse") >= 0 || n.indexOf("input-mouse") >= 0) return "Mouse"
        if (n.indexOf("tablet") >= 0 || n.indexOf("input-tablet") >= 0) return "Tablet"
        if (n.indexOf("gaming") >= 0 || n.indexOf("joypad") >= 0) return "Controller"
        if (n.indexOf("computer") >= 0) return "Computer"
        return "Device"
    }

    function btBattery(infoText) {
        const m = /Battery Percentage:\s*0x[\da-fA-F]+\s*\((\d+)\)/.exec(infoText)
        if (m) return parseInt(m[1])
        return -1
    }

    Timer {
        id: settle
        interval: 1800
        onTriggered: root.refresh()
    }

    // --- bluetoothctl show ---
    Process {
        id: show
        command: ["bluetoothctl", "show"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.available = text.indexOf("Controller") >= 0
                root.enabled = /Powered:\s*yes/.test(text)
                if (root.enabled) connDevs.running = true
                else root.device = ""
            }
        }
    }

    // --- connected devices (for the pill label) ---
    Process {
        id: connDevs
        command: ["bluetoothctl", "devices", "Connected"]
        stdout: StdioCollector {
            onStreamFinished: {
                const first = text.split("\n").filter(l => l.startsWith("Device "))[0]
                if (first) {
                    const parts = first.split(" ")
                    root._activeMac = parts[1] || ""
                    root.device = parts.slice(2).join(" ")
                    activeInfoProc.running = true
                } else {
                    root.device = ""
                    root._activeMac = ""
                    root.battery = -1
                }
            }
        }
    }

    // --- battery for the connected device ---
    Process {
        id: activeInfoProc
        command: ["bluetoothctl", "info", root._activeMac]
        stdout: StdioCollector {
            onStreamFinished: {
                root.battery = root.btBattery(text)
            }
        }
    }

    // --- full paired device list with per-device info ---
    Process {
        id: detailProc
        command: ["sh", "-c",
            "macs=$(bluetoothctl devices Paired | awk '{print $2}');" +
            "conn=$(bluetoothctl devices Connected | awk '{print $2}');" +
            "for m in $macs; do" +
            "  echo '---DEVICE---';" +
            "  echo \"MAC:$m\";" +
            "  echo \"$conn\" | grep -qx \"$m\" && echo 'CONNECTED:yes' || echo 'CONNECTED:no';" +
            "  bluetoothctl info \"$m\" 2>/dev/null;" +
            "done"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.scanning = false
                const blocks = text.split("---DEVICE---").filter(b => b.trim() !== "")
                const list = []
                for (let i = 0; i < blocks.length; i++) {
                    const b = blocks[i]
                    const macM = /MAC:([0-9A-Fa-f:]+)/.exec(b)
                    if (!macM) continue
                    const mac = macM[1]
                    const connected = b.indexOf("CONNECTED:yes") >= 0
                    const nameM = /Name:\s*(.+)/.exec(b)
                    const name = nameM ? nameM[1].trim() : mac
                    const iconM = /Icon:\s*(.+)/.exec(b)
                    const icon = iconM ? iconM[1].trim() : ""
                    const bat = root.btBattery(b)
                    list.push({
                        mac: mac,
                        name: name,
                        connected: connected,
                        kind: root.kindFromIcon(icon),
                        battery: bat
                    })
                }
                // Sort: connected first, then alphabetical
                list.sort((a, b) => {
                    if (a.connected !== b.connected) return a.connected ? -1 : 1
                    return a.name.localeCompare(b.name)
                })
                root.devicesList = list
            }
        }
    }

    // --- connect / disconnect / remove action ---
    Process {
        id: actionProc
        stdout: StdioCollector { id: actOut }
        stderr: StdioCollector { id: actErr }
        onExited: (exitCode, exitStatus) => {
            const mac = root.busyMac
            root.busyMac = ""
            root.busyAction = ""
            if (exitCode !== 0) {
                const raw = (actErr.text || actOut.text || "").trim()
                root.errorMac = mac
                if (raw.indexOf("br-connection-key-missing") >= 0) {
                    root.errorKeyMissing = true
                    root.actionError = "Pairing key lost. Remove and re-pair this device."
                } else if (raw.indexOf("br-connection-page-timeout") >= 0) {
                    root.actionError = "Device not responding. Make sure it is in range and powered on."
                } else {
                    const msg = raw.replace(/^.*Failed.*:\s*/i, "").split("\n")[0]
                    root.actionError = msg !== "" ? msg : "Action failed"
                }
            } else {
                root.actionError = ""
                root.errorMac = ""
                root.errorKeyMissing = false
            }
            root.refresh()
            root.loadDevices()
        }
    }
}

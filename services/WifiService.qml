import Quickshell
import Quickshell.Io
import QtQuick

// Wi-Fi radio state, current network name, and live throughput via nmcli + /proc/net/dev.
Scope {
    id: root

    property bool available: true
    property bool enabled: false
    property string ssid: ""
    property string iface: ""
    property bool active: false
    property bool hasSpeed: false
    property real rxSpeed: 0
    property real txSpeed: 0

    property var networks: []
    property var savedNames: ({})
    property bool scanning: false
    property string connectingSsid: ""
    property string connectError: ""

    property string _connectTarget: ""
    property string _lastDev: ""
    property real _lastRx: 0
    property real _lastTx: 0
    property double _lastTime: 0
    property bool _primed: false

    signal connectionFailed(string ssid, string error)

    readonly property bool speedActive: active && enabled && (ssid !== "" || iface !== "")

    function refresh() { radio.running = true }

    function scan(rescan) {
        if (!enabled) {
            networks = []
            scanning = false
            return
        }
        if (!savedProc.running) savedProc.running = true
        if (!listProc.running) listProc.running = true
        if (rescan) {
            scanning = true
            if (!rescanProc.running) rescanProc.running = true
        }
    }

    function connectTo(targetSsid, password) {
        if (connectingSsid !== "" || targetSsid === "") return
        connectError = ""
        connectingSsid = targetSsid
        _connectTarget = targetSsid
        const cmd = ["nmcli", "dev", "wifi", "connect", targetSsid]
        if (password !== undefined && password !== "") {
            cmd.push("password", password)
        }
        connectProc.exec(cmd)
    }

    function splitNmcli(line) {
        const fields = []
        let cur = ""
        for (let i = 0; i < line.length; i++) {
            if (line[i] === "\\" && i + 1 < line.length) {
                cur += line[i + 1]
                i++
            } else if (line[i] === ":") {
                fields.push(cur)
                cur = ""
            } else {
                cur += line[i]
            }
        }
        fields.push(cur)
        return fields
    }

    function parseNetworks(text) {
        const bySsid = {}
        const lines = text.split("\n")
        for (let i = 0; i < lines.length; i++) {
            if (lines[i] === "") continue
            const cols = splitNmcli(lines[i])
            if (cols.length < 4) continue
            const inUse = cols[0].trim() === "*"
            const name = cols[1]
            if (name === "") continue
            const signal = parseInt(cols[2]) || 0
            const security = cols[3].trim()
            const secured = security !== "" && security !== "--"

            const prev = bySsid[name]
            if (!prev) {
                bySsid[name] = {
                    ssid: name,
                    signal: signal,
                    security: security === "--" ? "" : security,
                    secured: secured,
                    inUse: inUse,
                    saved: !!root.savedNames[name]
                }
            } else {
                if (inUse) prev.inUse = true
                if (signal > prev.signal) {
                    prev.signal = signal
                    prev.security = security === "--" ? "" : security
                    prev.secured = secured
                }
            }
        }

        const list = []
        for (const k in bySsid) list.push(bySsid[k])
        list.sort((a, b) => {
            if (a.inUse !== b.inUse) return a.inUse ? -1 : 1
            return b.signal - a.signal
        })
        root.networks = list
    }

    function resetSpeed() {
        _primed = false
        _lastDev = ""
        hasSpeed = false
        rxSpeed = 0
        txSpeed = 0
    }

    function formatSpeed(bps) {
        if (bps < 1024) return Math.round(bps) + " B/s"
        if (bps < 1048576) {
            const kb = bps / 1024
            return (kb >= 100 ? Math.round(kb) : kb.toFixed(1)) + " KB/s"
        }
        if (bps < 1073741824) {
            const mb = bps / 1048576
            return (mb >= 100 ? Math.round(mb) : mb.toFixed(1)) + " MB/s"
        }
        return (bps / 1073741824).toFixed(1) + " GB/s"
    }

    function toggle() {
        enabled = !enabled
        connectError = ""
        if (!enabled) {
            ssid = ""
            iface = ""
            networks = []
            scanning = false
            resetSpeed()
        }
        Quickshell.execDetached(["nmcli", "radio", "wifi", enabled ? "on" : "off"])
        settle.restart()
    }

    onSpeedActiveChanged: {
        if (speedActive) {
            resetSpeed()
            if (!sampleProc.running) sampleProc.running = true
            speedTimer.interval = 450
            speedTimer.restart()
        } else {
            speedTimer.stop()
            resetSpeed()
        }
    }

    Timer {
        id: settle
        interval: 1800
        onTriggered: root.refresh()
    }

    Timer {
        id: speedTimer
        interval: 1000
        repeat: true
        onTriggered: {
            interval = 1000
            if (root.speedActive && !sampleProc.running) sampleProc.running = true
        }
    }

    Process {
        id: radio
        command: ["nmcli", "radio", "wifi"]
        stdout: StdioCollector {
            onStreamFinished: {
                const state = text.trim()
                root.available = state !== ""
                root.enabled = state === "enabled"
                if (root.enabled) {
                    ssidProc.running = true
                    ifaceProc.running = true
                } else {
                    root.ssid = ""
                    root.iface = ""
                    root.networks = []
                    root.scanning = false
                }
            }
        }
    }

    Process {
        id: ifaceProc
        command: ["nmcli", "-t", "-f", "DEVICE,TYPE,STATE", "dev"]
        stdout: StdioCollector {
            onStreamFinished: {
                let found = ""
                const lines = text.split("\n")
                for (let i = 0; i < lines.length; i++) {
                    const parts = lines[i].split(":")
                    if (parts.length >= 3 && parts[1] === "wifi" && parts[2].startsWith("connected")) {
                        found = parts[0]
                        break
                    }
                }
                root.iface = found
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

    Process {
        id: savedProc
        command: ["nmcli", "-t", "-f", "NAME,TYPE", "connection", "show"]
        stdout: StdioCollector {
            onStreamFinished: {
                const map = {}
                const lines = text.split("\n")
                for (let i = 0; i < lines.length; i++) {
                    const cols = root.splitNmcli(lines[i])
                    if (cols.length >= 2 && (cols[1] === "802-11-wireless" || cols[1] === "wifi")) {
                        map[cols[0]] = true
                    }
                }
                root.savedNames = map
                if (root.networks.length > 0) {
                    const updated = root.networks.map(n => ({
                        ssid: n.ssid,
                        signal: n.signal,
                        security: n.security,
                        secured: n.secured,
                        inUse: n.inUse,
                        saved: !!map[n.ssid]
                    }))
                    root.networks = updated
                }
            }
        }
    }

    Process {
        id: listProc
        command: ["nmcli", "-t", "-f", "IN-USE,SSID,SIGNAL,SECURITY", "dev", "wifi", "list", "--rescan", "no"]
        stdout: StdioCollector {
            onStreamFinished: root.parseNetworks(text)
        }
    }

    Process {
        id: rescanProc
        command: ["nmcli", "-t", "-f", "IN-USE,SSID,SIGNAL,SECURITY", "dev", "wifi", "list", "--rescan", "yes"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.scanning = false
                root.parseNetworks(text)
            }
        }
        onExited: root.scanning = false
    }

    Process {
        id: connectProc
        stdout: StdioCollector { id: connectOut }
        stderr: StdioCollector { id: connectErr }
        onExited: (exitCode, exitStatus) => {
            const target = root._connectTarget
            root.connectingSsid = ""
            if (exitCode === 0) {
                root.connectError = ""
                root.refresh()
                root.scan(false)
                settle.restart()
            } else {
                const raw = (connectErr.text || connectOut.text || "").trim()
                const msg = raw.replace(/^Error:\s*/i, "").split("\n")[0]
                root.connectError = msg !== "" ? msg : ("Could not connect to " + target)
                root.connectionFailed(target, root.connectError)
            }
        }
    }

    Process {
        id: sampleProc
        command: ["cat", "/proc/net/dev"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (!root.speedActive) return
                const lines = text.split("\n")
                let foundDev = ""
                let foundRx = -1
                let foundTx = -1
                for (let i = 2; i < lines.length; i++) {
                    const line = lines[i]
                    const colon = line.indexOf(":")
                    if (colon < 0) continue
                    const dev = line.slice(0, colon).trim()
                    const matches = root.iface !== ""
                        ? (dev === root.iface)
                        : (dev.startsWith("wl") && !dev.startsWith("wlp2p"))
                    if (!matches) continue
                    const cols = line.slice(colon + 1).trim().split(/\s+/)
                    if (cols.length >= 9) {
                        const rx = parseFloat(cols[0])
                        const tx = parseFloat(cols[8])
                        if (!isNaN(rx) && !isNaN(tx)) {
                            foundDev = dev
                            foundRx = rx
                            foundTx = tx
                            break
                        }
                    }
                }
                if (foundRx < 0) return
                const now = Date.now()
                if (root._primed && foundDev === root._lastDev) {
                    const dt = (now - root._lastTime) / 1000.0
                    if (dt > 0.05 && foundRx >= root._lastRx && foundTx >= root._lastTx) {
                        root.rxSpeed = (foundRx - root._lastRx) / dt
                        root.txSpeed = (foundTx - root._lastTx) / dt
                        root.hasSpeed = true
                    }
                }
                root._lastDev = foundDev
                root._lastRx = foundRx
                root._lastTx = foundTx
                root._lastTime = now
                root._primed = true
            }
        }
    }
}

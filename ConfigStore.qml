import Quickshell
import Quickshell.Io
import QtQuick

// Loads ~/.config/kde-island/config.json and hot-reloads it whenever the file is saved.
// Missing or invalid keys silently fall back to the defaults below.
Scope {
    id: root

    readonly property string file: (Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/kde-island/config.json"

    readonly property var defaults: ({
        monitor: "",
        topMargin: 8,
        pillWidth: 124,
        pillHeight: 32,
        panelWidth: 392,
        cornerRadius: 32,
        tint: "#0c0c10",
        glassOpacity: 0.8,
        accent: "#f2f2f7",
        borderGlow: 0.1,
        animationSpeed: 1.0,
        use24h: true,
        readingTemperature: 3600
    })

    property var values: defaults

    readonly property string monitor: values.monitor
    readonly property real topMargin: values.topMargin
    readonly property real pillWidth: values.pillWidth
    readonly property real pillHeight: values.pillHeight
    readonly property real panelWidth: values.panelWidth
    readonly property real cornerRadius: values.cornerRadius
    readonly property string tint: values.tint
    readonly property real glassOpacity: values.glassOpacity
    readonly property string accent: values.accent
    readonly property real borderGlow: values.borderGlow
    readonly property real animationSpeed: Math.max(0.2, values.animationSpeed)
    readonly property bool use24h: values.use24h
    readonly property int readingTemperature: values.readingTemperature

    function parse(raw) {
        try {
            const user = JSON.parse(raw)
            const merged = {}
            for (const key in defaults) {
                merged[key] = (typeof user[key] === typeof defaults[key]) ? user[key] : defaults[key]
            }
            values = merged
        } catch (e) {
            console.warn("kde-island: could not parse config.json, keeping previous values:", e)
        }
    }

    FileView {
        path: root.file
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.parse(text())
        onLoadFailed: root.values = root.defaults
    }
}

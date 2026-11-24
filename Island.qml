import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.UPower
import "components"

// The whole UI: a black pill that morphs into the command center.
// The parent window is a transparent full-screen overlay; only the island's
// rectangle (or the whole screen while open) receives input.
Item {
    id: root

    required property var cfg
    required property var audio
    required property var brightness
    required property var wifi
    required property var bluetooth
    required property var reading
    required property var media

    property bool open: false
    property string subView: ""
    property alias hitbox: hit

    readonly property var player: media.player
    readonly property bool playing: player !== null && player !== undefined && player.isPlaying

    readonly property real pad: 18
    readonly property color accent: cfg.accent
    readonly property color tint: cfg.tint

    // 0 = pill, 1 = full panel. Opens with a soft overshoot, closes without one.
    property real progress: open ? 1 : 0
    Behavior on progress {
        NumberAnimation {
            duration: (root.open ? 480 : 300) / root.cfg.animationSpeed
            easing.type: root.open ? Easing.OutBack : Easing.InOutCubic
            easing.overshoot: 0.8
        }
    }
    readonly property real p: Math.max(0, progress)
    readonly property real pc: Math.min(1, p)

    // Pill widens for the music live-activity and grows a little on hover.
    property real pillW: (playing ? 190 : cfg.pillWidth) + ((!open && hoverArea.containsMouse) ? 10 : 0)
    Behavior on pillW {
        NumberAnimation { duration: 280; easing.type: Easing.OutBack; easing.overshoot: 1.2 }
    }

    // Panel height follows its content (animates if rows appear/disappear).
    property real panelH: content.implicitHeight + pad * 2
    Behavior on panelH {
        NumberAnimation { duration: 260; easing.type: Easing.OutCubic }
    }

    // Battery
    readonly property var bat: UPower.displayDevice
    readonly property bool batteryPresent: bat !== null && bat !== undefined && bat.isPresent
    readonly property bool charging: batteryPresent && bat.state === UPowerDeviceState.Charging
    readonly property int batteryPct: batteryPresent ? Math.round(bat.percentage * 100) : 0

    // Staggered reveal: row i fades/slides in slightly after row i-1.
    function rev(i) {
        return Math.max(0, Math.min(1, (progress - 0.30 - i * 0.07) / 0.40))
    }

    function refreshAll() {
        wifi.refresh()
        bluetooth.refresh()
        reading.refresh()
        brightness.refresh()
    }

    focus: true
    Keys.onEscapePressed: {
        if (root.subView === "wifi") {
            if (wifiPanel.passwordSsid !== "") {
                wifiPanel.passwordSsid = ""
            } else {
                root.subView = ""
            }
        } else if (root.subView === "reading") {
            root.subView = ""
        } else {
            root.open = false
        }
    }

    onSubViewChanged: {
        if (open && subView === "") forceActiveFocus()
    }

    onOpenChanged: {
        wifi.active = open
        if (open) {
            forceActiveFocus()
            refreshAll()
        } else {
            subView = ""
            wifiPanel.reset()
        }
    }
    Component.onCompleted: {
        wifi.active = open
        refreshAll()
    }

    Timer {
        running: root.open
        repeat: true
        interval: 4000
        onTriggered: {
            root.wifi.refresh()
            root.bluetooth.refresh()
            if (root.subView === "wifi" && root.wifi.enabled) root.wifi.scan(false)
        }
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    // Click anywhere outside the panel to close it.
    MouseArea {
        anchors.fill: parent
        enabled: root.open
        onClicked: root.open = false
    }

    RectangularShadow {
        x: island.x
        y: island.y
        width: island.width
        height: island.height
        radius: island.radius
        blur: 40
        offset: Qt.vector2d(0, 12)
        color: Qt.rgba(0, 0, 0, 0.5 * root.pc)
        visible: root.pc > 0.01
    }

    Rectangle {
        id: island

        anchors.horizontalCenter: parent.horizontalCenter
        y: root.cfg.topMargin
        width: root.pillW + (root.cfg.panelWidth - root.pillW) * root.p
        height: root.cfg.pillHeight + (root.panelH - root.cfg.pillHeight) * root.p
        radius: Math.min(height / 2, root.cfg.pillHeight / 2 + (root.cfg.cornerRadius - root.cfg.pillHeight / 2) * root.pc)
        clip: true

        // Pure black pill -> tinted translucent glass.
        color: Qt.rgba(root.tint.r * root.pc, root.tint.g * root.pc, root.tint.b * root.pc,
                       1 - (1 - root.cfg.glassOpacity) * root.pc)
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, root.cfg.borderGlow * root.pc)

        // Soft top highlight
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.07 * root.pc) }
                GradientStop { position: 0.45; color: Qt.rgba(1, 1, 1, 0) }
            }
        }

        // Click to open (while closed); swallows clicks while open so they don't close it.
        MouseArea {
            id: hoverArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: root.open ? Qt.ArrowCursor : Qt.PointingHandCursor
            onClicked: if (!root.open) root.open = true
        }

        // Pill state: music live-activity
        Item {
            width: parent.width
            height: root.cfg.pillHeight
            opacity: Math.max(0, 1 - root.p * 4)
            visible: opacity > 0.01

            Item {
                anchors.fill: parent
                opacity: root.playing ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 200 } }

                ClippingRectangle {
                    width: 20
                    height: 20
                    radius: 10
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    color: Qt.rgba(1, 1, 1, 0.12)

                    Image {
                        anchors.fill: parent
                        source: root.player ? root.player.trackArtUrl : ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }
                }

                EqBars {
                    anchors.right: parent.right
                    anchors.rightMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    running: root.playing && !root.open
                }
            }
        }

        // Panel state
        Item {
            id: content

            x: (parent.width - width) / 2
            y: root.pad
            width: root.cfg.panelWidth - root.pad * 2
            implicitHeight: {
                if (root.subView === "wifi") return wifiPanel.implicitHeight
                if (root.subView === "reading") return readingPanel.implicitHeight
                return mainCol.implicitHeight
            }
            visible: root.p > 0.02
            enabled: root.open

            Column {
                id: mainCol
                width: content.width
                spacing: 12
                opacity: root.subView === "" ? 1 : 0
                visible: opacity > 0.01
                enabled: root.subView === ""
                Behavior on opacity { NumberAnimation { duration: 160 } }

            // 0 — clock + battery
            Item {
                width: content.width
                height: 52
                opacity: root.rev(0)
                transform: Translate { y: (1 - root.rev(0)) * 14 }

                Column {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 1

                    Text {
                        text: Qt.formatDateTime(clock.date, root.cfg.use24h ? "HH:mm" : "h:mm AP")
                        color: "#ffffff"
                        font.pixelSize: 28
                        font.weight: Font.DemiBold
                    }
                    Text {
                        text: Qt.formatDateTime(clock.date, "dddd, d MMMM")
                        color: Qt.rgba(1, 1, 1, 0.55)
                        font.pixelSize: 12
                    }
                }

                Rectangle {
                    visible: root.batteryPresent
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    height: 30
                    width: batRow.implicitWidth + 22
                    radius: 15
                    color: Qt.rgba(1, 1, 1, 0.08)

                    Row {
                        id: batRow
                        anchors.centerIn: parent
                        spacing: 6

                        Icon {
                            anchors.verticalCenter: parent.verticalCenter
                            name: root.charging ? "bolt" : "battery"
                            size: 15
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.batteryPct + "%"
                            color: "#ffffff"
                            font.pixelSize: 13
                            font.weight: Font.Medium
                        }
                    }
                }
            }

            // 1 — quick toggles
            Grid {
                id: tiles
                width: content.width
                columns: 2
                spacing: 10
                opacity: root.rev(1)
                transform: Translate { y: (1 - root.rev(1)) * 14 }

                Tile {
                    width: (tiles.width - tiles.spacing) / 2
                    height: 66
                    icon: "wifi"
                    iconClickable: true
                    title: "Wi-Fi"
                    subtitle: root.wifi.enabled ? (root.wifi.ssid !== "" ? root.wifi.ssid : "Not connected") : "Off"
                    badgeTop: (root.wifi.enabled && (root.wifi.ssid !== "" || root.wifi.iface !== "") && root.wifi.hasSpeed)
                        ? ("↓ " + root.wifi.formatSpeed(root.wifi.rxSpeed)) : ""
                    badgeBottom: (root.wifi.enabled && (root.wifi.ssid !== "" || root.wifi.iface !== "") && root.wifi.hasSpeed)
                        ? ("↑ " + root.wifi.formatSpeed(root.wifi.txSpeed)) : ""
                    active: root.wifi.enabled
                    accent: root.accent
                    onClicked: root.wifi.toggle()
                    onIconClicked: {
                        root.wifi.scan(true)
                        root.subView = "wifi"
                    }
                }
                Tile {
                    width: (tiles.width - tiles.spacing) / 2
                    height: 66
                    icon: "bluetooth"
                    title: "Bluetooth"
                    subtitle: root.bluetooth.enabled ? (root.bluetooth.device !== "" ? root.bluetooth.device : "On") : "Off"
                    active: root.bluetooth.enabled
                    accent: root.accent
                    onClicked: root.bluetooth.toggle()
                }
                Tile {
                    width: (tiles.width - tiles.spacing) / 2
                    height: 66
                    icon: "book"
                    iconClickable: true
                    title: "Reading"
                    subtitle: root.reading.active ? ("Warm · " + root.reading.temperature + "K") : "Off"
                    badgeTop: root.reading.active ? (root.reading.temperature + "K") : ""
                    active: root.reading.active
                    accent: root.accent
                    onClicked: root.reading.toggle()
                    onIconClicked: root.subView = "reading"
                }
                Tile {
                    width: (tiles.width - tiles.spacing) / 2
                    height: 66
                    icon: "sliders"
                    title: "Settings"
                    subtitle: "System Settings"
                    accent: root.accent
                    onClicked: {
                        Quickshell.execDetached(["systemsettings"])
                        root.open = false
                    }
                }
            }

            // 2 — brightness
            GlassSlider {
                width: content.width
                height: 48
                opacity: root.rev(2)
                transform: Translate { y: (1 - root.rev(2)) * 14 }
                icon: "sun"
                value: root.brightness.level
                enabled: root.brightness.available
                accent: root.accent
                onMoved: v => root.brightness.setLevel(v)
            }

            // 3 — volume
            GlassSlider {
                width: content.width
                height: 48
                opacity: root.rev(3)
                transform: Translate { y: (1 - root.rev(3)) * 14 }
                icon: (root.audio.muted || root.audio.volume <= 0.001) ? "vol0" : (root.audio.volume < 0.5 ? "vol1" : "vol2")
                value: root.audio.muted ? 0 : root.audio.volume
                enabled: root.audio.ready
                accent: root.accent
                onMoved: v => root.audio.setVolume(v)
                onIconClicked: root.audio.toggleMute()
            }

            // 4 — media player
            MediaCard {
                width: content.width
                height: 112
                opacity: root.rev(4)
                transform: Translate { y: (1 - root.rev(4)) * 14 }
                player: root.player
                accent: root.accent
            }
            }

            WifiPanel {
                id: wifiPanel
                width: content.width
                wifi: root.wifi
                accent: root.accent
                opacity: root.subView === "wifi" ? 1 : 0
                visible: opacity > 0.01
                enabled: root.subView === "wifi"
                Behavior on opacity { NumberAnimation { duration: 160 } }
                onBack: root.subView = ""
            }

            ReadingPanel {
                id: readingPanel
                width: content.width
                reading: root.reading
                accent: root.accent
                opacity: root.subView === "reading" ? 1 : 0
                visible: opacity > 0.01
                enabled: root.subView === "reading"
                Behavior on opacity { NumberAnimation { duration: 160 } }
                onBack: root.subView = ""
            }
        }
    }

    // Input region used by the window mask: the pill while closed, the whole screen while open.
    Item {
        id: hit
        x: root.open ? 0 : island.x - 6
        y: root.open ? 0 : island.y - 4
        width: root.open ? root.width : island.width + 12
        height: root.open ? root.height : island.height + 8
    }
}

import QtQuick

// Paired Bluetooth devices panel shown when clicking the Bluetooth icon disc.
Column {
    id: root

    required property var bluetooth
    property color accent: "#f2f2f7"
    signal back()

    readonly property bool lightAccent: (0.299 * accent.r + 0.587 * accent.g + 0.114 * accent.b) > 0.55

    spacing: 10

    function reset() {
        bluetooth.actionError = ""
        bluetooth.errorMac = ""
        bluetooth.errorKeyMissing = false
    }

    // Header: Back + Bluetooth status + Refresh + On/Off pill
    Item {
        width: parent.width
        height: 36

        IconButton {
            id: backBtn
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            size: 32
            glyph: 17
            icon: "back"
            accent: root.accent
            onClicked: {
                root.reset()
                root.back()
            }
        }

        Column {
            anchors.left: backBtn.right
            anchors.leftMargin: 8
            anchors.right: headerActions.left
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            spacing: 0

            Text {
                width: parent.width
                text: "Bluetooth"
                color: "#ffffff"
                font.pixelSize: 15
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }

            Text {
                width: parent.width
                text: {
                    if (!root.bluetooth.enabled) return "Off"
                    if (root.bluetooth.scanning) return "Scanning…"
                    if (root.bluetooth.device !== "") {
                        let s = root.bluetooth.device
                        if (root.bluetooth.battery >= 0) s += " · " + root.bluetooth.battery + "%"
                        return s
                    }
                    return "No devices connected"
                }
                color: Qt.rgba(1, 1, 1, 0.55)
                font.pixelSize: 11
                elide: Text.ElideRight
            }
        }

        Row {
            id: headerActions
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            IconButton {
                anchors.verticalCenter: parent.verticalCenter
                size: 30
                glyph: 15
                icon: "refresh"
                accent: root.accent
                enabled: root.bluetooth.enabled && !root.bluetooth.scanning
                onClicked: root.bluetooth.loadDevices()
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 48
                height: 26
                radius: 13
                color: root.bluetooth.enabled ? root.accent : Qt.rgba(1, 1, 1, toggleMa.containsMouse ? 0.18 : 0.12)
                Behavior on color { ColorAnimation { duration: 160 } }

                Text {
                    anchors.centerIn: parent
                    text: root.bluetooth.enabled ? "On" : "Off"
                    color: (root.bluetooth.enabled && root.lightAccent) ? "#111114" : "#ffffff"
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                }

                MouseArea {
                    id: toggleMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.bluetooth.toggle()
                }
            }
        }
    }

    // Error banner
    Rectangle {
        visible: root.bluetooth.actionError !== ""
        width: parent.width
        height: visible ? errCol.implicitHeight + 16 : 0
        radius: 14
        color: Qt.rgba(0.94, 0.27, 0.27, 0.20)
        border.width: 1
        border.color: Qt.rgba(0.94, 0.27, 0.27, 0.40)

        Column {
            id: errCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 10
            spacing: 8

            Text {
                width: parent.width
                text: root.bluetooth.actionError
                color: "#fca5a5"
                font.pixelSize: 11
                wrapMode: Text.Wrap
            }

            Row {
                visible: root.bluetooth.errorKeyMissing
                spacing: 8

                Rectangle {
                    width: 64
                    height: 26
                    radius: 13
                    color: Qt.rgba(1, 1, 1, forgetMa.containsMouse ? 0.16 : 0.09)

                    Text {
                        anchors.centerIn: parent
                        text: "Forget"
                        color: "#fca5a5"
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                    }

                    MouseArea {
                        id: forgetMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.bluetooth.forgetDevice(root.bluetooth.errorMac)
                        }
                    }
                }

                Rectangle {
                    width: 110
                    height: 26
                    radius: 13
                    color: Qt.rgba(1, 1, 1, pairMa.containsMouse ? 0.16 : 0.09)

                    Text {
                        anchors.centerIn: parent
                        text: "Pair in Settings"
                        color: "#ffffff"
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                    }

                    MouseArea {
                        id: pairMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.bluetooth.openSettings()
                    }
                }
            }
        }
    }

    // Devices list container
    Rectangle {
        width: parent.width
        height: {
            if (!root.bluetooth.enabled || root.bluetooth.devicesList.length === 0) return 104
            return Math.min(256, devList.contentHeight + 12)
        }
        radius: 22
        color: Qt.rgba(1, 1, 1, 0.07)
        clip: true

        // Empty / Off state
        Column {
            visible: !root.bluetooth.enabled || root.bluetooth.devicesList.length === 0
            anchors.centerIn: parent
            spacing: 8

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: !root.bluetooth.enabled
                    ? "Bluetooth is turned off"
                    : (root.bluetooth.scanning ? "Searching for devices…" : "No paired devices")
                color: Qt.rgba(1, 1, 1, 0.55)
                font.pixelSize: 13
            }

            Rectangle {
                visible: !root.bluetooth.enabled
                anchors.horizontalCenter: parent.horizontalCenter
                width: 130
                height: 30
                radius: 15
                color: root.accent

                Text {
                    anchors.centerIn: parent
                    text: "Turn On Bluetooth"
                    color: root.lightAccent ? "#111114" : "#ffffff"
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.bluetooth.toggle()
                }
            }
        }

        ListView {
            id: devList
            visible: root.bluetooth.enabled && root.bluetooth.devicesList.length > 0
            anchors.fill: parent
            anchors.margins: 6
            spacing: 2
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            model: root.bluetooth.devicesList

            delegate: Rectangle {
                id: row
                required property var modelData

                readonly property bool isBusy: root.bluetooth.busyMac === modelData.mac
                readonly property string statusText: {
                    if (isBusy) return root.bluetooth.busyAction
                    if (modelData.connected) return "Connected"
                    return modelData.kind || "Paired"
                }

                width: devList.width
                height: 46
                radius: 16
                color: {
                    if (modelData.connected) return Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.16)
                    if (rowMa.containsMouse) return Qt.rgba(1, 1, 1, 0.09)
                    return "transparent"
                }
                Behavior on color { ColorAnimation { duration: 130 } }

                // Bluetooth signal dot
                Rectangle {
                    id: btDot
                    anchors.left: parent.left
                    anchors.leftMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    width: 8
                    height: 8
                    radius: 4
                    color: modelData.connected ? root.accent : Qt.rgba(1, 1, 1, 0.30)
                    Behavior on color { ColorAnimation { duration: 160 } }
                }

                Column {
                    anchors.left: btDot.right
                    anchors.leftMargin: 11
                    anchors.right: rowRight.left
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 1

                    Text {
                        width: parent.width
                        text: row.modelData.name
                        color: "#ffffff"
                        font.pixelSize: 13
                        font.weight: row.modelData.connected ? Font.DemiBold : Font.Medium
                        elide: Text.ElideRight
                    }

                    Text {
                        width: parent.width
                        text: row.statusText
                        color: row.modelData.connected
                            ? Qt.rgba(1, 1, 1, 0.80)
                            : Qt.rgba(1, 1, 1, 0.48)
                        font.pixelSize: 11
                        elide: Text.ElideRight
                    }
                }

                Row {
                    id: rowRight
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    Text {
                        visible: row.modelData.battery >= 0
                        anchors.verticalCenter: parent.verticalCenter
                        text: row.modelData.battery + "%"
                        color: Qt.rgba(1, 1, 1, 0.65)
                        font.pixelSize: 11
                        font.weight: Font.Medium
                    }

                    Icon {
                        visible: row.modelData.connected
                        anchors.verticalCenter: parent.verticalCenter
                        name: "check"
                        size: 15
                    }
                }

                MouseArea {
                    id: rowMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: (row.isBusy || root.bluetooth.busyMac !== "")
                        ? Qt.ArrowCursor : Qt.PointingHandCursor
                    onClicked: {
                        if (row.isBusy || root.bluetooth.busyMac !== "") return
                        root.bluetooth.toggleDevice(row.modelData)
                    }
                }
            }
        }
    }
}

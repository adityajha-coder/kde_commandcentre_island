import QtQuick

// Available Wi-Fi networks picker shown when clicking the Wi-Fi icon.
Column {
    id: root

    required property var wifi
    property color accent: "#f2f2f7"
    property string passwordSsid: ""
    property bool showPassword: false
    signal back()

    readonly property bool lightAccent: (0.299 * accent.r + 0.587 * accent.g + 0.114 * accent.b) > 0.55

    spacing: 10

    function reset() {
        passwordSsid = ""
        showPassword = false
        pwdInput.text = ""
        wifi.connectError = ""
    }

    function submitPassword() {
        if (passwordSsid === "" || pwdInput.text.length === 0) return
        const target = passwordSsid
        const pwd = pwdInput.text
        passwordSsid = ""
        pwdInput.text = ""
        wifi.connectTo(target, pwd)
    }

    Connections {
        target: root.wifi
        function onConnectionFailed(ssid, error) {
            if (!root.visible) return
            root.passwordSsid = ssid
            pwdInput.text = ""
            pwdInput.forceActiveFocus()
        }
    }

    // Header: Back + Wi-Fi status + Rescan + On/Off pill
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
                text: "Wi-Fi"
                color: "#ffffff"
                font.pixelSize: 15
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }

            Text {
                width: parent.width
                text: {
                    if (!root.wifi.enabled) return "Off"
                    if (root.wifi.connectingSsid !== "") return "Connecting to " + root.wifi.connectingSsid + "…"
                    if (root.wifi.scanning) return "Scanning…"
                    if (root.wifi.ssid !== "") {
                        return root.wifi.ssid + (root.wifi.hasSpeed ? (" · ↓ " + root.wifi.formatSpeed(root.wifi.rxSpeed)) : "")
                    }
                    return "Not connected"
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
                enabled: root.wifi.enabled && !root.wifi.scanning
                onClicked: root.wifi.scan(true)
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 48
                height: 26
                radius: 13
                color: root.wifi.enabled ? root.accent : Qt.rgba(1, 1, 1, toggleMa.containsMouse ? 0.18 : 0.12)
                Behavior on color { ColorAnimation { duration: 160 } }

                Text {
                    anchors.centerIn: parent
                    text: root.wifi.enabled ? "On" : "Off"
                    color: (root.wifi.enabled && root.lightAccent) ? "#111114" : "#ffffff"
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                }

                MouseArea {
                    id: toggleMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.passwordSsid = ""
                        root.wifi.toggle()
                    }
                }
            }
        }
    }

    // Error banner
    Rectangle {
        visible: root.wifi.connectError !== ""
        width: parent.width
        height: errText.implicitHeight + 14
        radius: 14
        color: Qt.rgba(0.94, 0.27, 0.27, 0.20)
        border.width: 1
        border.color: Qt.rgba(0.94, 0.27, 0.27, 0.40)

        Text {
            id: errText
            anchors.fill: parent
            anchors.margins: 10
            text: root.wifi.connectError
            color: "#fca5a5"
            font.pixelSize: 11
            wrapMode: Text.Wrap
            verticalAlignment: Text.AlignVCenter
        }
    }

    // Inline password prompt for secured networks
    Rectangle {
        visible: root.passwordSsid !== "" && root.wifi.enabled
        width: parent.width
        height: pwdCol.implicitHeight + 20
        radius: 18
        color: Qt.rgba(1, 1, 1, 0.10)

        Column {
            id: pwdCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 10
            spacing: 8

            Text {
                width: parent.width
                text: "Password for " + root.passwordSsid
                color: "#ffffff"
                font.pixelSize: 12
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }

            Rectangle {
                width: parent.width
                height: 34
                radius: 17
                color: Qt.rgba(0, 0, 0, 0.30)
                border.width: 1
                border.color: pwdInput.activeFocus ? Qt.rgba(1, 1, 1, 0.35) : Qt.rgba(1, 1, 1, 0.10)

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.right: showBtn.left
                    anchors.rightMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Enter Wi-Fi password"
                    color: Qt.rgba(1, 1, 1, 0.38)
                    font.pixelSize: 12
                    visible: pwdInput.text.length === 0
                }

                TextInput {
                    id: pwdInput
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.right: showBtn.left
                    anchors.rightMargin: 6
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    verticalAlignment: TextInput.AlignVCenter
                    color: "#ffffff"
                    font.pixelSize: 12
                    clip: true
                    selectByMouse: true
                    echoMode: root.showPassword ? TextInput.Normal : TextInput.Password
                    Keys.onReturnPressed: root.submitPassword()
                    Keys.onEnterPressed: root.submitPassword()
                    Keys.onEscapePressed: event => {
                        root.passwordSsid = ""
                        pwdInput.text = ""
                        event.accepted = true
                    }
                }

                Text {
                    id: showBtn
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.showPassword ? "Hide" : "Show"
                    color: Qt.rgba(1, 1, 1, 0.65)
                    font.pixelSize: 11
                    font.weight: Font.Medium

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -4
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.showPassword = !root.showPassword
                    }
                }
            }

            Row {
                anchors.right: parent.right
                spacing: 8

                Rectangle {
                    width: 64
                    height: 28
                    radius: 14
                    color: Qt.rgba(1, 1, 1, cancelMa.containsMouse ? 0.16 : 0.09)

                    Text {
                        anchors.centerIn: parent
                        text: "Cancel"
                        color: "#ffffff"
                        font.pixelSize: 12
                    }

                    MouseArea {
                        id: cancelMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.passwordSsid = ""
                            pwdInput.text = ""
                        }
                    }
                }

                Rectangle {
                    width: 74
                    height: 28
                    radius: 14
                    color: root.accent
                    opacity: pwdInput.text.length > 0 ? 1 : 0.45

                    Text {
                        anchors.centerIn: parent
                        text: "Connect"
                        color: root.lightAccent ? "#111114" : "#ffffff"
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: pwdInput.text.length > 0
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.submitPassword()
                    }
                }
            }
        }
    }

    // Networks list container
    Rectangle {
        width: parent.width
        height: {
            if (!root.wifi.enabled || root.wifi.networks.length === 0) return 104
            return Math.min(256, netList.contentHeight + 12)
        }
        radius: 22
        color: Qt.rgba(1, 1, 1, 0.07)
        clip: true

        // Empty / Off state
        Column {
            visible: !root.wifi.enabled || root.wifi.networks.length === 0
            anchors.centerIn: parent
            spacing: 8

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: !root.wifi.enabled
                    ? "Wi-Fi is turned off"
                    : (root.wifi.scanning ? "Searching for networks…" : "No networks found")
                color: Qt.rgba(1, 1, 1, 0.55)
                font.pixelSize: 13
            }

            Rectangle {
                visible: !root.wifi.enabled
                anchors.horizontalCenter: parent.horizontalCenter
                width: 112
                height: 30
                radius: 15
                color: root.accent

                Text {
                    anchors.centerIn: parent
                    text: "Turn On Wi-Fi"
                    color: root.lightAccent ? "#111114" : "#ffffff"
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.wifi.toggle()
                        scanAfterOn.restart()
                    }
                }
            }
        }

        Timer {
            id: scanAfterOn
            interval: 1200
            onTriggered: if (root.wifi.enabled) root.wifi.scan(true)
        }

        ListView {
            id: netList
            visible: root.wifi.enabled && root.wifi.networks.length > 0
            anchors.fill: parent
            anchors.margins: 6
            spacing: 2
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            model: root.wifi.networks

            delegate: Rectangle {
                id: row
                required property var modelData

                readonly property bool isConnecting: root.wifi.connectingSsid === modelData.ssid

                width: netList.width
                height: 46
                radius: 16
                color: {
                    if (modelData.inUse) return Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.16)
                    if (rowMa.containsMouse) return Qt.rgba(1, 1, 1, 0.09)
                    return "transparent"
                }
                Behavior on color { ColorAnimation { duration: 130 } }

                // Signal strength bars
                Row {
                    id: sigBars
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2
                    height: 14

                    Repeater {
                        model: [15, 40, 65, 85]
                        Rectangle {
                            required property int index
                            required property int modelData
                            width: 3
                            height: 4 + index * 3
                            radius: 1.5
                            anchors.bottom: parent.bottom
                            color: row.modelData.signal >= modelData
                                ? (row.modelData.inUse ? root.accent : "#ffffff")
                                : Qt.rgba(1, 1, 1, 0.22)
                        }
                    }
                }

                Column {
                    anchors.left: sigBars.right
                    anchors.leftMargin: 11
                    anchors.right: rowRight.left
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 1

                    Text {
                        width: parent.width
                        text: row.modelData.ssid
                        color: "#ffffff"
                        font.pixelSize: 13
                        font.weight: row.modelData.inUse ? Font.DemiBold : Font.Medium
                        elide: Text.ElideRight
                    }

                    Text {
                        width: parent.width
                        text: {
                            if (row.isConnecting) return "Connecting…"
                            if (row.modelData.inUse) return "Connected"
                            if (row.modelData.saved) return "Saved"
                            return row.modelData.security !== "" ? row.modelData.security : "Open"
                        }
                        color: row.modelData.inUse
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

                    Icon {
                        visible: row.modelData.secured && !row.modelData.inUse
                        anchors.verticalCenter: parent.verticalCenter
                        name: "lock"
                        size: 13
                        opacity: 0.55
                    }

                    Icon {
                        visible: row.modelData.inUse
                        anchors.verticalCenter: parent.verticalCenter
                        name: "check"
                        size: 15
                    }
                }

                MouseArea {
                    id: rowMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: (row.modelData.inUse || root.wifi.connectingSsid !== "")
                        ? Qt.ArrowCursor : Qt.PointingHandCursor
                    onClicked: {
                        if (row.modelData.inUse || root.wifi.connectingSsid !== "") return
                        root.wifi.connectError = ""
                        if (!row.modelData.secured || row.modelData.saved) {
                            root.passwordSsid = ""
                            root.wifi.connectTo(row.modelData.ssid, "")
                        } else {
                            root.passwordSsid = row.modelData.ssid
                            pwdInput.text = ""
                            pwdInput.forceActiveFocus()
                        }
                    }
                }
            }
        }
    }
}

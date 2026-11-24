import QtQuick

// Reading mode warmth customization view shown when clicking the Reading icon.
Column {
    id: root

    required property var reading
    property color accent: "#f2f2f7"
    signal back()

    readonly property int minTemp: 1500
    readonly property int maxTemp: 6500
    readonly property bool lightAccent: (0.299 * accent.r + 0.587 * accent.g + 0.114 * accent.b) > 0.55
    readonly property real warmth: Math.max(0, Math.min(1, (maxTemp - reading.temperature) / (maxTemp - minTemp)))

    readonly property var presets: [
        { label: "Soft", k: 4500 },
        { label: "Reading", k: 3600 },
        { label: "Warm", k: 2800 },
        { label: "Candle", k: 2000 }
    ]

    spacing: 12

    function setFromWarmth(w) {
        const clamped = Math.max(0, Math.min(1, w))
        const kelvin = Math.round((maxTemp - clamped * (maxTemp - minTemp)) / 100) * 100
        reading.setTemperature(kelvin, true)
    }

    // Header: Back + Reading Mode status + On/Off pill
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
            onClicked: root.back()
        }

        Column {
            anchors.left: backBtn.right
            anchors.leftMargin: 8
            anchors.right: togglePill.left
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            spacing: 0

            Text {
                width: parent.width
                text: "Reading Mode"
                color: "#ffffff"
                font.pixelSize: 15
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }

            Text {
                width: parent.width
                text: root.reading.active
                    ? ("Warm · " + root.reading.temperature + "K")
                    : ("Off · " + root.reading.temperature + "K")
                color: Qt.rgba(1, 1, 1, 0.55)
                font.pixelSize: 11
                elide: Text.ElideRight
            }
        }

        Rectangle {
            id: togglePill
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: 48
            height: 26
            radius: 13
            color: root.reading.active ? root.accent : Qt.rgba(1, 1, 1, toggleMa.containsMouse ? 0.18 : 0.12)
            Behavior on color { ColorAnimation { duration: 160 } }

            Text {
                anchors.centerIn: parent
                text: root.reading.active ? "On" : "Off"
                color: (root.reading.active && root.lightAccent) ? "#111114" : "#ffffff"
                font.pixelSize: 12
                font.weight: Font.DemiBold
            }

            MouseArea {
                id: toggleMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.reading.toggle()
            }
        }
    }

    // Warmth slider (left = cooler 6500K, right = warmer 1500K)
    Item {
        id: slider
        width: parent.width
        height: 48

        property real dragWarmth: 0
        readonly property real shown: dragArea.pressed ? dragWarmth : root.warmth

        function updateFromX(x) {
            dragWarmth = Math.max(0, Math.min(1, (x - height / 2) / Math.max(1, width - height)))
            root.setFromWarmth(dragWarmth)
        }

        scale: (sliderHover.hovered || dragArea.pressed) ? 1.015 : 1
        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

        HoverHandler { id: sliderHover }

        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: Qt.rgba(1, 1, 1, sliderHover.hovered ? 0.14 : 0.09)
            Behavior on color { ColorAnimation { duration: 150 } }
        }

        Rectangle {
            id: fill
            height: parent.height
            width: height + (parent.width - height) * slider.shown
            radius: height / 2
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "#fde68a" }
                GradientStop { position: 1.0; color: "#f97316" }
            }

            Behavior on width {
                enabled: !dragArea.pressed
                NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
            }
        }

        MouseArea {
            id: dragArea
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onPressed: mouse => slider.updateFromX(mouse.x)
            onPositionChanged: mouse => { if (pressed) slider.updateFromX(mouse.x) }
            onWheel: wheel => root.setFromWarmth(root.warmth + wheel.angleDelta.y / 2400)
        }

        Item {
            width: parent.height
            height: parent.height

            Icon {
                anchors.centerIn: parent
                name: "book"
                size: 20
                dark: 1
            }
        }

        Text {
            anchors.right: parent.right
            anchors.rightMargin: 18
            anchors.verticalCenter: parent.verticalCenter
            text: root.reading.temperature + "K"
            color: slider.shown > 0.80 ? "#111114" : "#ffffff"
            font.pixelSize: 12
            font.weight: Font.DemiBold
            opacity: 0.85
            Behavior on color { ColorAnimation { duration: 140 } }
        }
    }

    // Labels under slider
    Item {
        width: parent.width
        height: 14

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 6
            text: "Neutral"
            color: Qt.rgba(1, 1, 1, 0.45)
            font.pixelSize: 11
        }

        Text {
            anchors.right: parent.right
            anchors.rightMargin: 6
            text: "Warmest"
            color: Qt.rgba(1, 1, 1, 0.45)
            font.pixelSize: 11
        }
    }

    // Quick presets
    Row {
        width: parent.width
        spacing: 8

        Repeater {
            model: root.presets

            Rectangle {
                id: presetBtn
                required property var modelData
                readonly property bool selected: Math.abs(root.reading.temperature - modelData.k) <= 50

                width: (parent.width - 8 * 3) / 4
                height: 50
                radius: 16
                color: selected
                    ? root.accent
                    : Qt.rgba(1, 1, 1, pMa.containsMouse ? 0.14 : 0.08)
                scale: pMa.pressed ? 0.96 : (pMa.containsMouse ? 1.02 : 1)
                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutBack } }

                Column {
                    anchors.centerIn: parent
                    spacing: 1

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: presetBtn.modelData.label
                        color: (presetBtn.selected && root.lightAccent) ? "#111114" : "#ffffff"
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: presetBtn.modelData.k + "K"
                        color: (presetBtn.selected && root.lightAccent)
                            ? Qt.rgba(0.07, 0.07, 0.08, 0.65)
                            : Qt.rgba(1, 1, 1, 0.55)
                        font.pixelSize: 10
                    }
                }

                MouseArea {
                    id: pMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.reading.setTemperature(presetBtn.modelData.k, true)
                }
            }
        }
    }
}

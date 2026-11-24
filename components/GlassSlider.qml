import QtQuick

// iOS-style pill slider: the icon sits on a round "thumb" that grows into the fill.
// Drag, click or use the mouse wheel. Click the icon to emit iconClicked().
Item {
    id: root

    property string icon: "sun"
    property real value: 0              // 0..1
    property color accent: "#f2f2f7"
    signal moved(real v)
    signal iconClicked()

    property real dragValue: 0
    readonly property real shown: dragArea.pressed ? dragValue : value
    readonly property bool lightAccent: (0.299 * accent.r + 0.587 * accent.g + 0.114 * accent.b) > 0.55

    function clamp01(x) { return Math.max(0, Math.min(1, x)) }

    function setFromX(x) {
        dragValue = clamp01((x - height / 2) / Math.max(1, width - height))
        moved(dragValue)
    }

    scale: (hover.hovered || dragArea.pressed) ? 1.015 : 1
    Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

    HoverHandler { id: hover }

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: Qt.rgba(1, 1, 1, hover.hovered ? 0.14 : 0.09)
        opacity: root.enabled ? 1 : 0.5
        Behavior on color { ColorAnimation { duration: 150 } }
    }

    Rectangle {
        id: fill
        height: parent.height
        width: height + (parent.width - height) * root.shown
        radius: height / 2
        color: root.accent
        opacity: root.enabled ? 1 : 0.5

        Behavior on width {
            enabled: !dragArea.pressed
            NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
        }
    }

    MouseArea {
        id: dragArea
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onPressed: mouse => root.setFromX(mouse.x)
        onPositionChanged: mouse => { if (pressed) root.setFromX(mouse.x) }
        onWheel: wheel => root.moved(root.clamp01(root.value + wheel.angleDelta.y / 2400))
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        x: fill.width - width - 18
        text: Math.round(root.shown * 100)
        color: root.lightAccent ? "#111114" : "#ffffff"
        font.pixelSize: 13
        font.weight: Font.DemiBold
        opacity: root.shown > 0.25 ? 0.6 : 0
        Behavior on opacity { NumberAnimation { duration: 150 } }
    }

    Item {
        width: parent.height
        height: parent.height

        Icon {
            anchors.centerIn: parent
            name: root.icon
            size: 20
            dark: root.lightAccent ? 1 : 0
            scale: iconArea.containsMouse ? 1.22 : 1
            Behavior on scale { NumberAnimation { duration: 240; easing.type: Easing.OutBack; easing.overshoot: 2.2 } }
        }

        MouseArea {
            id: iconArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.iconClicked()
        }
    }
}

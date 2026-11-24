import QtQuick

// Round icon button that grows on hover and squishes on press.
Item {
    id: btn

    property string icon: ""
    property real size: 30
    property real glyph: 16
    property bool filled: false
    property color accent: "#f2f2f7"
    signal clicked()

    readonly property bool lightAccent: (0.299 * accent.r + 0.587 * accent.g + 0.114 * accent.b) > 0.55

    width: size
    height: size
    opacity: enabled ? 1 : 0.35
    scale: ma.pressed ? 0.88 : (ma.containsMouse ? 1.18 : 1)

    Behavior on scale {
        NumberAnimation { duration: 200; easing.type: Easing.OutBack; easing.overshoot: 2 }
    }

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: btn.filled ? btn.accent : (ma.containsMouse ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(1, 1, 1, 0))
        Behavior on color { ColorAnimation { duration: 150 } }
    }

    Icon {
        anchors.centerIn: parent
        name: btn.icon
        size: btn.glyph
        dark: (btn.filled && btn.lightAccent) ? 1 : 0
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: btn.clicked()
    }
}

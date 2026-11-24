import QtQuick

// Quick-toggle tile: icon disc + title + status line.
Rectangle {
    id: tile

    property string icon: ""
    property string title: ""
    property string subtitle: ""
    property bool active: false
    property color accent: "#f2f2f7"
    signal clicked()

    readonly property bool lightAccent: (0.299 * accent.r + 0.587 * accent.g + 0.114 * accent.b) > 0.55
    readonly property bool darkInk: active && lightAccent
    readonly property color ink: darkInk ? "#111114" : "#ffffff"

    radius: 24
    color: active ? accent : Qt.rgba(1, 1, 1, ma.containsMouse ? 0.13 : 0.08)
    scale: ma.pressed ? 0.965 : (ma.containsMouse ? 1.025 : 1)

    Behavior on color { ColorAnimation { duration: 180 } }
    Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }

    Rectangle {
        id: disc
        x: 13
        anchors.verticalCenter: parent.verticalCenter
        width: 40
        height: 40
        radius: 20
        color: tile.active ? (tile.darkInk ? Qt.rgba(0, 0, 0, 0.10) : Qt.rgba(1, 1, 1, 0.22)) : Qt.rgba(1, 1, 1, 0.12)
        Behavior on color { ColorAnimation { duration: 180 } }

        Icon {
            anchors.centerIn: parent
            name: tile.icon
            size: 20
            dark: tile.darkInk ? 1 : 0
            scale: ma.containsMouse ? 1.22 : 1

            Behavior on dark { NumberAnimation { duration: 180 } }
            Behavior on scale { NumberAnimation { duration: 240; easing.type: Easing.OutBack; easing.overshoot: 2.2 } }
        }
    }

    Column {
        anchors.left: disc.right
        anchors.leftMargin: 11
        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        spacing: 1

        Text {
            width: parent.width
            text: tile.title
            color: tile.ink
            font.pixelSize: 14
            font.weight: Font.DemiBold
            elide: Text.ElideRight
            Behavior on color { ColorAnimation { duration: 180 } }
        }

        Text {
            width: parent.width
            text: tile.subtitle
            color: Qt.rgba(tile.ink.r, tile.ink.g, tile.ink.b, 0.6)
            font.pixelSize: 12
            elide: Text.ElideRight
            Behavior on color { ColorAnimation { duration: 180 } }
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: tile.clicked()
    }
}

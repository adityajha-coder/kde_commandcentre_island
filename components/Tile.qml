import QtQuick

// Quick-toggle tile: icon disc + title + status line.
Rectangle {
    id: tile

    property string icon: ""
    property string title: ""
    property string subtitle: ""
    property string badgeTop: ""
    property string badgeBottom: ""
    property bool iconClickable: false
    property bool active: false
    property color accent: "#f2f2f7"
    signal clicked()
    signal iconClicked()

    readonly property bool hasBadge: badgeTop !== "" || badgeBottom !== ""

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
        color: {
            if (tile.active) {
                const base = tile.darkInk ? 0.10 : 0.22
                const boost = (tile.iconClickable && iconMa.containsMouse) ? 0.10 : 0
                return tile.darkInk ? Qt.rgba(0, 0, 0, base + boost) : Qt.rgba(1, 1, 1, base + boost)
            }
            return Qt.rgba(1, 1, 1, (tile.iconClickable && iconMa.containsMouse) ? 0.20 : 0.12)
        }
        Behavior on color { ColorAnimation { duration: 180 } }

        Icon {
            anchors.centerIn: parent
            name: tile.icon
            size: 20
            dark: tile.darkInk ? 1 : 0
            scale: (tile.iconClickable ? iconMa.containsMouse : ma.containsMouse) ? 1.22 : 1

            Behavior on dark { NumberAnimation { duration: 180 } }
            Behavior on scale { NumberAnimation { duration: 240; easing.type: Easing.OutBack; easing.overshoot: 2.2 } }
        }
    }

    Column {
        anchors.left: disc.right
        anchors.leftMargin: 11
        anchors.right: tile.hasBadge ? badgeCol.left : parent.right
        anchors.rightMargin: tile.hasBadge ? 6 : 10
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

    Item {
        id: badgeCol
        visible: tile.hasBadge
        width: Math.max(topBadge.visible ? topBadge.implicitWidth : 0,
                        botBadge.visible ? botBadge.implicitWidth : 0)
        height: (topBadge.visible ? topBadge.implicitHeight : 0)
              + (botBadge.visible ? botBadge.implicitHeight : 0)
              + ((topBadge.visible && botBadge.visible) ? 2 : 0)
        anchors.right: parent.right
        anchors.rightMargin: 14
        anchors.verticalCenter: parent.verticalCenter

        Text {
            id: topBadge
            anchors.top: parent.top
            anchors.right: parent.right
            visible: tile.badgeTop !== ""
            text: tile.badgeTop
            color: Qt.rgba(tile.ink.r, tile.ink.g, tile.ink.b, 0.72)
            font.pixelSize: 10
            font.weight: Font.Medium
            Behavior on color { ColorAnimation { duration: 180 } }
        }

        Text {
            id: botBadge
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            visible: tile.badgeBottom !== ""
            text: tile.badgeBottom
            color: Qt.rgba(tile.ink.r, tile.ink.g, tile.ink.b, 0.55)
            font.pixelSize: 10
            font.weight: Font.Medium
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

    MouseArea {
        id: iconMa
        anchors.fill: disc
        anchors.margins: -6
        enabled: tile.iconClickable
        visible: tile.iconClickable
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: tile.iconClicked()
    }
}

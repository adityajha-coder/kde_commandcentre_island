import QtQuick
import Quickshell.Widgets

// Compact MPRIS player: art, title, artist, transport controls, time and a seek bar.
Rectangle {
    id: card

    property var player: null
    property color accent: "#f2f2f7"

    readonly property bool has: player !== null && player !== undefined
    readonly property real ratio: (has && player.length > 0) ? Math.max(0, Math.min(1, player.position / player.length)) : 0

    radius: 26
    color: Qt.rgba(1, 1, 1, 0.08)

    function fmt(sec) {
        const s = Math.max(0, Math.floor(sec || 0))
        return Math.floor(s / 60) + ":" + (s % 60 < 10 ? "0" : "") + (s % 60)
    }

    // MPRIS does not push position updates, so poke it while playing.
    Timer {
        running: card.visible && card.has && card.player.isPlaying
        interval: 500
        repeat: true
        onTriggered: card.player.positionChanged()
    }

    ClippingRectangle {
        id: art
        x: 16
        y: 14
        width: 68
        height: 68
        radius: 16
        color: Qt.rgba(1, 1, 1, 0.08)

        Icon {
            anchors.centerIn: parent
            name: "music"
            size: 26
            opacity: artImage.status === Image.Ready ? 0 : 0.5
        }

        Image {
            id: artImage
            anchors.fill: parent
            source: card.has ? card.player.trackArtUrl : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            opacity: status === Image.Ready ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 250 } }
        }
    }

    Text {
        x: 100
        y: 12
        width: card.width - 100 - 16
        text: card.has ? (card.player.trackTitle || "Unknown title") : "Nothing playing"
        color: "#ffffff"
        font.pixelSize: 15
        font.weight: Font.DemiBold
        elide: Text.ElideRight
    }

    Text {
        x: 100
        y: 33
        width: card.width - 100 - 16
        text: card.has ? (card.player.trackArtist || card.player.identity || "") : "Play something to see it here"
        color: Qt.rgba(1, 1, 1, 0.55)
        font.pixelSize: 12
        elide: Text.ElideRight
    }

    Row {
        id: controlsRow
        x: 100
        y: 54
        spacing: 4

        IconButton {
            anchors.verticalCenter: parent.verticalCenter
            size: 30
            glyph: 16
            icon: "prev"
            accent: card.accent
            enabled: card.has && card.player.canGoPrevious
            onClicked: card.player.previous()
        }

        IconButton {
            anchors.verticalCenter: parent.verticalCenter
            size: 34
            glyph: 16
            icon: (card.has && card.player.isPlaying) ? "pause" : "play"
            filled: true
            accent: card.accent
            enabled: card.has && card.player.canTogglePlaying
            onClicked: card.player.togglePlaying()
        }

        IconButton {
            anchors.verticalCenter: parent.verticalCenter
            size: 30
            glyph: 16
            icon: "next"
            accent: card.accent
            enabled: card.has && card.player.canGoNext
            onClicked: card.player.next()
        }
    }

    Text {
        anchors.right: parent.right
        anchors.rightMargin: 16
        anchors.verticalCenter: controlsRow.verticalCenter
        visible: card.has && card.player.length > 0
        text: card.fmt(card.has ? card.player.position : 0) + " / " + card.fmt(card.has ? card.player.length : 0)
        color: Qt.rgba(1, 1, 1, 0.45)
        font.pixelSize: 11
    }

    Item {
        id: seek
        x: 16
        y: card.height - 24
        width: card.width - 32
        height: 16

        Rectangle {
            id: seekTrack
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: (seekArea.containsMouse || seekArea.pressed) ? 6 : 4
            radius: height / 2
            color: Qt.rgba(1, 1, 1, 0.14)
            Behavior on height { NumberAnimation { duration: 120 } }

            Rectangle {
                width: parent.width * (seekArea.pressed ? seekArea.dragRatio : card.ratio)
                height: parent.height
                radius: parent.radius
                color: Qt.rgba(1, 1, 1, 0.9)
            }
        }

        MouseArea {
            id: seekArea
            anchors.fill: parent
            hoverEnabled: true
            enabled: card.has && card.player.canSeek && card.player.length > 0
            property real dragRatio: 0

            function apply(mx) {
                dragRatio = Math.max(0, Math.min(1, mx / width))
                card.player.position = dragRatio * card.player.length
            }

            onPressed: mouse => apply(mouse.x)
            onPositionChanged: mouse => { if (pressed) apply(mouse.x) }
        }
    }
}

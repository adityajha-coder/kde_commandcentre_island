import QtQuick

// Tiny animated equaliser shown in the pill while music plays.
Row {
    id: eq

    property bool running: false

    spacing: 2.5
    height: 16

    Repeater {
        model: 4

        Rectangle {
            id: bar
            required property int index

            width: 3
            height: 6
            radius: 1.5
            y: (eq.height - height) / 2
            color: "#ffffff"
            opacity: 0.9

            SequentialAnimation on height {
                running: eq.running
                loops: Animation.Infinite
                NumberAnimation { to: 14; duration: 260 + bar.index * 80; easing.type: Easing.InOutSine }
                NumberAnimation { to: 4; duration: 260 + bar.index * 80; easing.type: Easing.InOutSine }
            }
        }
    }
}

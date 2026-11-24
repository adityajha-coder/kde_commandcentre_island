import QtQuick

// Feather-style line icon from assets/icons. `dark` cross-fades between the white
// and the dark variant (0 = white, 1 = dark) so icons can follow a changing background.
Item {
    id: root

    property string name: ""
    property real size: 22
    property real dark: 0

    width: size
    height: size

    readonly property url lightSource: Qt.resolvedUrl("../assets/icons/" + name + ".svg")
    readonly property url darkSource: Qt.resolvedUrl("../assets/icons/" + name + "-dark.svg")

    Image {
        anchors.fill: parent
        source: root.lightSource
        sourceSize: Qt.size(root.size * 2, root.size * 2)
        smooth: true
        mipmap: true
        opacity: 1 - root.dark
        visible: opacity > 0.01
    }

    Image {
        anchors.fill: parent
        source: root.darkSource
        sourceSize: Qt.size(root.size * 2, root.size * 2)
        smooth: true
        mipmap: true
        opacity: root.dark
        visible: opacity > 0.01
    }
}

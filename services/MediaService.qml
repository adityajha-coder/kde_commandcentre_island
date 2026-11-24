import Quickshell
import Quickshell.Services.Mpris
import QtQuick

// Picks the MPRIS player to show: the one that is playing, otherwise the first available.
Scope {
    id: root

    readonly property var player: {
        const list = Mpris.players.values
        for (let i = 0; i < list.length; i++) {
            if (list[i].isPlaying) return list[i]
        }
        return list.length > 0 ? list[0] : null
    }
}

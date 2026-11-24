import Quickshell
import Quickshell.Wayland
import QtQuick
import "services"

// KDE Island — entry point. Run with:  quickshell -c kde-island   (or: quickshell -p <this folder>)
ShellRoot {
    ConfigStore { id: config }
    AudioService { id: audioSvc }
    BrightnessService { id: brightnessSvc }
    WifiService { id: wifiSvc }
    BluetoothService { id: bluetoothSvc }
    ReadingService {
        id: readingSvc
        temperature: config.readingTemperature
        onTemperatureCommitted: k => config.setReadingTemperature(k)
    }
    MediaService { id: mediaSvc }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property var modelData

            screen: modelData
            // One island only: the configured monitor, or the first screen.
            visible: config.monitor !== "" ? modelData.name === config.monitor : modelData === Quickshell.screens[0]

            // Full-screen transparent overlay; the mask below keeps everything outside the island click-through.
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"

            WlrLayershell.namespace: "kde-island"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: island.open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

            mask: Region { item: island.hitbox }

            Island {
                id: island
                anchors.fill: parent
                cfg: config
                audio: audioSvc
                brightness: brightnessSvc
                wifi: wifiSvc
                bluetooth: bluetoothSvc
                reading: readingSvc
                media: mediaSvc
            }
        }
    }
}

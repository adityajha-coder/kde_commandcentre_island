# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Added
- **Wi-Fi Switcher & Live Speeds**: Live `↓`/`↑` throughput badges on the Wi-Fi tile via `/proc/net/dev`, plus a dedicated `WifiPanel` (opened by clicking the Wi-Fi icon) to scan, switch networks, and enter passwords inline.
- **Bluetooth Device Switcher & Battery**: Dedicated `BluetoothPanel` (opened by clicking the Bluetooth icon) to list paired devices, connect/disconnect, view per-device battery percentage and device type, and handle pairing-key errors (`Forget` / `Pair in Settings`). Connected device battery percentage also appears as a badge on the Bluetooth tile.
- **Reading Mode Warmth Customization**: Dedicated `ReadingPanel` (opened by clicking the Reading icon) with a 1500K–6500K warmth slider, 4 quick presets (`Soft`, `Reading`, `Warm`, `Candle`), and automatic saving to `config.json`.
- **UI Icons**: Added `back`, `refresh`, `lock`, and `check` SVG icon pairs (light and dark variants).
- **CI Checks**: Updated `.github/workflows/ci.yml` to run on `dev`, validate integer `font.pixelSize` values in QML, and verify all new panels and services in the CMake install test.

### Fixed
- **Reading Mode**: Added `--notify` to `kwriteconfig6` and `qdbus-qt6` fallback in `scripts/reading-mode.sh` so KWin Night Light applies changes reliably.
- **Layout & Text Overlap**: Adjusted `MediaCard` height/spacing and Reading tile subtitle/badge layout to prevent overlapping text, and fixed a `Column` width binding loop in `Tile.qml`.

## [0.1.0] - 2026-11-24

### Initial Release
- **Dynamic Island**: Floating top pill that morphs into a glass control center.
- **Media Live Activity**: Pill expands during audio playback with album art and animated equalizer.
- **System Controls**: Sliders for volume (PipeWire) and brightness (PowerDevil/brightnessctl).
- **Quick Toggles**: Wi-Fi (nmcli), Bluetooth (bluetoothctl), Reading Mode (KWin Night Color), and System Settings.
- **Customization**: JSON configuration (`~/.config/kde-island/config.json`) with instant hot-reloading.
- **Tooling**: Automated installer (`install.sh`), desktop autostart, and CMake support.

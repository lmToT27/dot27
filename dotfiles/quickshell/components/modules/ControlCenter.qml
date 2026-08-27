import QtQuick
import QtQuick.Layouts
import Quickshell
import "../common"
import "../../services"
import "panels"

// Control Center's content: focus timer, Wi-Fi/Bluetooth status, weather +
// system monitor, media bar, and volume/brightness sliders. Long-pressing
// either connectivity card launches that protocol's own management GUI as
// a niri floating window (see ../../../niri/rules.kdl's wifi-float /
// blueman-manager rules) rather than an in-panel device list.
// Pure content Item — no window, no background of its own. Embedded by
// ControlCenterWindow.qml, which owns the actual surface, slide animation,
// and corner shaping.
Item {
    id: root

    // Width is always externally imposed by ControlCenterWindow (fixed
    // panel width); only height needs to be reported upward so that window
    // can auto-hug this content instead of guessing a fixed value.
    implicitHeight: content.implicitHeight

    ColumnLayout {
        id: content
        anchors.fill: parent
        spacing: 14

        // Tier 1: Focus timer (left) and Wi-Fi/Bluetooth status (right),
        // explicit 50/50 split. Measured off `root.width`, not
        // `tier1Row.width` — binding a child's preferredWidth to its own
        // immediate RowLayout parent's width trips Qt Quick Layouts'
        // "recursive rearrange" guard; `root` is sized externally by
        // ControlCenterWindow, so its width is already resolved.
        RowLayout {
            id: tier1Row
            Layout.fillWidth: true
            spacing: 12

            FocusTimer {
                id: focusTimer
                Layout.fillWidth: true
                Layout.preferredWidth: root.width / 2
                Layout.alignment: Qt.AlignVCenter
            }

            ColumnLayout {
                id: statusColumn
                Layout.fillWidth: true
                Layout.preferredWidth: root.width / 2
                Layout.alignment: Qt.AlignVCenter
                spacing: 8

                // Both cards' combined height must land exactly on
                // FocusTimer's height, so the row reads balanced.
                readonly property real cardHeight: (focusTimer.implicitHeight - statusColumn.spacing) / 2

                ConnectionCard {
                    Layout.fillWidth: true
                    Layout.preferredHeight: statusColumn.cardHeight
                    icon: "󰤨"
                    active: NetworkService.wifiRadioEnabled
                    title: NetworkService.kind === "wifi" && NetworkService.essid.length > 0
                        ? NetworkService.essid : "Wi-Fi"
                    subtitle: !NetworkService.wifiRadioEnabled ? "Off"
                        : (NetworkService.kind === "wifi" ? "Connected" : "Disconnected")
                    onToggled: NetworkService.toggleRadio()
                    // nmtui in a floating terminal — `--class wifi-float`
                    // is what the niri rule keys off of.
                    onLongPressed: Quickshell.execDetached(["kitty", "--class", "wifi-float", "-e", "nmtui"])
                }

                ConnectionCard {
                    Layout.fillWidth: true
                    Layout.preferredHeight: statusColumn.cardHeight
                    icon: "󰂯"
                    active: BluetoothService.powered
                    title: "Bluetooth"
                    subtitle: !BluetoothService.powered ? "Off"
                        : (BluetoothService.connectedCount > 0 ? "Connected" : "Disconnected")
                    onToggled: BluetoothService.togglePower()
                    onLongPressed: Quickshell.execDetached(["blueman-manager"])
                }
            }
        }

        // Tier 2: weather + system usage.
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            WeatherWidget {}

            SystemMonitor {}
        }

        // Tier 3: media transport.
        MediaBar {
            Layout.fillWidth: true
        }

        // Tier 4: volume/brightness.
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 10

            SliderRow {
                Layout.fillWidth: true
                icon: AudioService.muted ? "󰖁" : "󰕾"
                dimmed: AudioService.muted
                value: AudioService.volume
                onMoved: pct => AudioService.setVolume(pct)
                onIconClicked: AudioService.toggleMute()
            }

            SliderRow {
                Layout.fillWidth: true
                icon: "󰃠"
                value: BrightnessService.percent
                onMoved: pct => BrightnessService.setPercent(pct)
            }
        }

        // Tier 5: power profile.
        PowerProfileSelector {}

        // Tier 6: power actions.
        PowerFooter {
            Layout.fillWidth: true
        }
    }
}

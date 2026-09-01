import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import "../../../config"
import "../../../services"

// Tier 2's left side: current condition + temperature, from WeatherService
// (wttr.in, IP-geolocated). Only polls while this panel is actually open.
Rectangle {
    id: root

    readonly property string icon: WeatherService.icon
    readonly property int temperature: WeatherService.temperature
    readonly property string condition: WeatherService.condition

    Binding {
        target: WeatherService
        property: "active"
        value: ControlCenterState.open
    }

    Layout.preferredWidth: 96
    Layout.preferredHeight: 84
    radius: Appearance.radiusInner
    color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.05)

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 2

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: root.icon
            font.family: Appearance.fontFamily
            font.pixelSize: 24
            color: Theme.accent
        }

        // Wrapped in a sized Item so the inner Text can carry an
        // anchors.*CenterOffset nudge without changing the Item's own
        // reported size (which is what Layout.alignment centers against).
        Item {
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: tempText.implicitWidth
            implicitHeight: tempText.implicitHeight

            Text {
                id: tempText
                anchors.centerIn: parent
                anchors.verticalCenterOffset: -2
                text: root.temperature + "°"
                font.family: Appearance.fontFamily
                font.bold: true
                font.pixelSize: 16
                color: Theme.fg
            }
        }

        // Fixed width (root.width minus 12px padding each side) so long
        // condition strings elide instead of overflowing the pill; the
        // wrapping Item mirrors that width so ColumnLayout centering and
        // the hover/tooltip area line up with the text box, not its
        // (now irrelevant) implicit text width.
        Item {
            Layout.alignment: Qt.AlignHCenter
            width: conditionText.width
            implicitHeight: conditionText.implicitHeight

            Text {
                id: conditionText
                anchors.centerIn: parent
                anchors.verticalCenterOffset: -2
                width: root.width - 24
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                clip: true
                text: root.condition
                font.family: Appearance.fontFamily
                font.pixelSize: 10
                color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.55)
            }

            MouseArea {
                id: conditionHover
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.NoButton
            }

            // Explicit ToolTip instance (see SystemMonitor.qml) so the
            // default background can be replaced. Only shown when the
            // text is actually eliding.
            ToolTip {
                id: conditionTip
                visible: conditionHover.containsMouse && conditionText.truncated
                delay: 400
                text: root.condition

                background: Rectangle {
                    color: Appearance.tooltipBg
                    radius: Appearance.radiusInner
                }

                contentItem: Text {
                    text: conditionTip.text
                    color: Theme.accent
                    font.family: Appearance.fontFamily
                    font.bold: true
                    font.pixelSize: 11
                }
            }
        }
    }
}

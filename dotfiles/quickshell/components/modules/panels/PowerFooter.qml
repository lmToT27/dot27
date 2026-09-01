import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import Quickshell
import "../../../config"
import "../../../services"

// Bottom-row power actions.
RowLayout {
    id: root

    spacing: 8

    readonly property var actions: [
        { icon: "\u{f033e}", tooltip: "Lock", command: ["hyprlock"], danger: false },
        { icon: "\u{f0343}", tooltip: "Log Out", command: ["niri", "msg", "action", "quit"], danger: false },
        { icon: "\u{f0709}", tooltip: "Reboot", command: ["systemctl", "reboot"], danger: false },
        { icon: "\u{f0425}", tooltip: "Power Off", command: ["systemctl", "poweroff"], danger: true }
    ]

    Repeater {
        model: root.actions

        Rectangle {
            id: btn
            required property var modelData

            Layout.fillWidth: true
            implicitHeight: 40
            radius: Appearance.radiusInner
            color: mouseArea.containsMouse
                ? (btn.modelData.danger ? Appearance.critical : Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.1))
                : Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.05)
            Behavior on color { ColorAnimation { duration: Appearance.animFast } }
            scale: mouseArea.pressed ? 0.95 : 1
            Behavior on scale { NumberAnimation { duration: 100 } }

            Text {
                anchors.centerIn: parent
                text: btn.modelData.icon
                font.family: Appearance.fontFamily
                font.pixelSize: 16
                color: mouseArea.containsMouse && btn.modelData.danger ? "white" : Theme.accent
                Behavior on color { ColorAnimation { duration: Appearance.animFast } }
            }

            MouseArea {
                id: mouseArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: Quickshell.execDetached(btn.modelData.command)
            }

            ToolTip {
                visible: mouseArea.containsMouse
                delay: 400
                text: btn.modelData.tooltip

                background: Rectangle {
                    color: Appearance.tooltipBg
                    radius: Appearance.radiusInner
                }

                contentItem: Text {
                    text: btn.modelData.tooltip
                    color: Theme.accent
                    font.family: Appearance.fontFamily
                    font.bold: true
                    font.pixelSize: 11
                }
            }
        }
    }
}

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import "../../../config"
import "../../../services"

// Tier 2's right side: RAM/CPU/GPU usage as icon + thin linear bar +
// percentage, from SystemStatsService (/proc/meminfo, /proc/stat,
// nvidia-smi). Only polls while this panel is actually open.
Rectangle {
    id: root

    readonly property var stats: [
        { icon: "󰘚", label: "RAM", prop: "ramPercent" },
        { icon: "󰍛", label: "CPU", prop: "cpuPercent" },
        { icon: "󰢮", label: "GPU", prop: "gpuPercent" }
    ]

    Binding {
        target: SystemStatsService
        property: "active"
        value: ControlCenterState.open
    }

    Layout.fillWidth: true
    Layout.preferredHeight: 84
    radius: Appearance.radiusInner
    color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.05)

    ColumnLayout {
        anchors.fill: parent
        // Equal top/bottom so the block reads centered in the card rather
        // than hugging its bottom edge.
        anchors.topMargin: 12
        anchors.bottomMargin: 12
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 6

        Repeater {
            model: root.stats

            // Plain Item, not a RowLayout, as the delegate root: the hover
            // MouseArea below needs to sit on top of the whole row without
            // itself becoming a 4th layout cell.
            Item {
                id: statRow
                required property var modelData
                readonly property real value: SystemStatsService[statRow.modelData.prop]

                Layout.fillWidth: true
                implicitHeight: rowContent.implicitHeight

                RowLayout {
                    id: rowContent
                    anchors.fill: parent
                    spacing: 8

                    Text {
                        text: statRow.modelData.icon
                        font.family: Appearance.fontFamily
                        font.pixelSize: 12
                        color: Theme.accent
                        Layout.preferredWidth: 14
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 6
                        radius: height / 2
                        color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.12)

                        Rectangle {
                            height: parent.height
                            radius: parent.radius
                            color: Theme.accent
                            width: parent.width * (statRow.value / 100)

                            Behavior on width {
                                NumberAnimation { duration: 800; easing.type: Easing.InOutQuad }
                            }
                        }
                    }

                    Text {
                        text: Math.round(statRow.value) + "%"
                        // Forced monospace + bold regardless of
                        // Appearance.fontFamily — the "btop" look wants
                        // these to read as a technical readout, decoupled
                        // from whatever the shell's general-purpose font
                        // happens to be.
                        font.family: "JetBrainsMono Nerd Font"
                        font.bold: true
                        font.pixelSize: 10
                        color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.7)
                        Layout.preferredWidth: 28
                        horizontalAlignment: Text.AlignRight
                    }
                }

                MouseArea {
                    id: hoverArea
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.NoButton
                }

                // Explicit ToolTip instance, not the attached property —
                // lets background/contentItem be replaced with a rounded
                // black pill instead of the style's default.
                ToolTip {
                    id: tip
                    visible: hoverArea.containsMouse
                    delay: 400
                    text: statRow.modelData.label + " Usage"

                    background: Rectangle {
                        color: Appearance.tooltipBg
                        radius: Appearance.radiusInner
                    }

                    contentItem: Text {
                        text: tip.text
                        color: Theme.accent
                        font.family: Appearance.fontFamily
                        font.bold: true
                        font.pixelSize: 11
                    }
                }
            }
        }
    }
}

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower
import "../../../config"
import "../../../services"

// Segmented Saver/Balanced/Performance control, backed by the same
// PowerProfileService the Topbar's PowerProfileIndicator cycles through —
// this just sets a specific profile directly instead of cycling.
Rectangle {
    id: root

    readonly property var profiles: [
        { profile: PowerProfile.PowerSaver, icon: "\u{f032a}", label: "Saver" },
        { profile: PowerProfile.Balanced, icon: "\u{f05d1}", label: "Balanced" },
        { profile: PowerProfile.Performance, icon: "\u{f04c5}", label: "Performance" }
    ]

    Layout.fillWidth: true
    implicitHeight: 36
    radius: Appearance.radiusInner
    color: Qt.rgba(1, 1, 1, 0.05)

    RowLayout {
        anchors.fill: parent
        anchors.margins: 4
        spacing: 4

        Repeater {
            model: root.profiles

            Rectangle {
                id: segment
                required property var modelData
                readonly property bool active: PowerProfileService.current === modelData.profile

                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: Appearance.radiusInner - 2
                color: segment.active ? Theme.accent : "transparent"
                Behavior on color { ColorAnimation { duration: Appearance.animFast } }
                scale: segMouseArea.pressed ? 0.95 : 1
                Behavior on scale { NumberAnimation { duration: 100 } }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 4

                    Text {
                        text: segment.modelData.icon
                        font.family: Appearance.fontFamily
                        font.pixelSize: 13
                        color: segment.active ? Theme.onAccent : Qt.rgba(1, 1, 1, 0.6)
                    }

                    Text {
                        text: segment.modelData.label
                        font.family: Appearance.fontFamily
                        font.pixelSize: 11
                        font.bold: true
                        color: segment.active ? Theme.onAccent : Qt.rgba(1, 1, 1, 0.6)
                    }
                }

                MouseArea {
                    id: segMouseArea
                    anchors.fill: parent
                    onClicked: PowerProfileService.setProfile(segment.modelData.profile)
                }
            }
        }
    }
}

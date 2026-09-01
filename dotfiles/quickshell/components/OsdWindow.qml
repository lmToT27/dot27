import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../config"
import "../services"

PanelWindow {
    id: root

    readonly property int pillWidth: 220
    readonly property int pillHeight: 40
    readonly property bool isBrightness: OsdState.kind === "brightness"
    readonly property real level: isBrightness ? BrightnessService.percent : AudioService.volume
    readonly property bool muted: !isBrightness && AudioService.muted
    readonly property real shownPct: muted ? 0 : Math.max(0, Math.min(100, level))

    anchors { bottom: true; left: false; right: false; top: false }
    margins.bottom: 30

    implicitWidth: pillWidth
    implicitHeight: pillHeight
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:osd"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    visible: false

    readonly property bool osdActive: OsdState.active

    onOsdActiveChanged: {
        if (root.osdActive) {
            root.visible = true
        } else {
            hideTimer.restart()
        }
    }

    Timer {
        id: hideTimer
        interval: Appearance.animFast + 50
        onTriggered: if (!root.osdActive) root.visible = false
    }

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: Appearance.tooltipBg
        border.width: 0
        border.color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.1)

        opacity: root.osdActive ? 1 : 0
        scale: root.osdActive ? 1 : 0.9
        Behavior on opacity { NumberAnimation { duration: Appearance.animFast; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: Appearance.animFast; easing.type: Easing.OutCubic } }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 18
            anchors.rightMargin: 18
            spacing: 12

            Text {
                font.family: Appearance.fontFamily
                font.pixelSize: 18
                color: Theme.accent
                text: {
                    if (root.isBrightness) return "󰃠"
                    if (root.muted || root.level <= 0) return "󰖁"
                    if (root.level < 33) return "󰕿"
                    if (root.level < 66) return "󰖀"
                    return "󰕾"
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 6
                radius: 3
                color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.15)

                Rectangle {
                    height: parent.height
                    width: parent.width * (root.shownPct / 100)
                    radius: 3
                    color: Theme.accent
                    Behavior on width { NumberAnimation { duration: Appearance.animFast; easing.type: Easing.OutCubic } }
                }
            }

            Text {
                Layout.preferredWidth: 34
                horizontalAlignment: Text.AlignRight
                font.family: Appearance.fontFamily
                font.pixelSize: 12
                font.weight: Font.DemiBold
                color: Theme.accent
                text: Math.round(root.shownPct) + "%"
            }
        }
    }
}

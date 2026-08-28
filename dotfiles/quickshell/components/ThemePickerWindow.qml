import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../config"
import "../services"

PanelWindow {
    id: root

    readonly property int pillWidth: 420
    readonly property int pillHeight: 100
    readonly property int contentMargin: 16
    readonly property int swatchSize: 60
    readonly property int pillRadius: 32

    readonly property bool pickerOpen: ThemePickerState.open

    implicitWidth: pillWidth
    implicitHeight: pillHeight
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:theme-picker"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    visible: root.pickerOpen

    onPickerOpenChanged: {
        if (root.pickerOpen) {
            colorInput.text = "#"
            Qt.callLater(() => colorInput.forceActiveFocus())
        }
    }

    Shortcut {
        sequence: "Escape"
        onActivated: ThemePickerState.hide()
    }

    function isValidHex(hex) {
        return /^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$/.test(hex)
    }

    function applyTheme(hexCode) {
        if (!root.isValidHex(hexCode)) return
        Quickshell.execDetached(["changetheme.sh", hexCode])
        ThemePickerState.hide()
    }

    Rectangle {
        anchors.fill: parent
        color: Appearance.tooltipBg
        radius: root.pillRadius
        border.width: 0
        border.color: Qt.rgba(1, 1, 1, 0.1)

        RowLayout {
            anchors.fill: parent
            anchors.margins: root.contentMargin
            spacing: root.contentMargin

            Rectangle {
                Layout.preferredWidth: root.swatchSize
                Layout.preferredHeight: root.swatchSize
                radius: Appearance.radiusOuter
                color: root.isValidHex(colorInput.text) ? colorInput.text : "transparent"
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.2)
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: Appearance.radiusOuter
                color: Qt.rgba(0, 0, 0, 0.4)

                TextInput {
                    id: colorInput
                    anchors.fill: parent
                    anchors.leftMargin: root.contentMargin
                    anchors.rightMargin: root.contentMargin
                    verticalAlignment: Text.AlignVCenter
                    font.family: Appearance.fontFamily
                    font.pixelSize: 18
                    color: "white"
                    text: "#"
                    clip: true
                    selectByMouse: true

                    Keys.onReturnPressed: root.applyTheme(text)
                    Keys.onEnterPressed: root.applyTheme(text)
                }
            }

            Rectangle {
                Layout.preferredWidth: root.swatchSize
                Layout.preferredHeight: root.swatchSize
                radius: Appearance.radiusOuter
                color: Qt.rgba(1, 1, 1, 0.1)

                Text {
                    anchors.centerIn: parent
                    text: "󰈋"
                    font.family: Appearance.fontFamily
                    font.pixelSize: 22
                    color: "white"
                }

                MouseArea {
                    id: eyedropperMouseArea
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true

                    Rectangle {
                        anchors.fill: parent
                        radius: Appearance.radiusOuter
                        color: "white"
                        opacity: eyedropperMouseArea.containsMouse ? 0.15 : 0
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                    }

                    onClicked: {
                        ThemePickerState.hide()
                        Quickshell.execDetached(["sh", "-c", "color=$(hyprpicker --format=hex) && [ -n \"$color\" ] && changetheme.sh \"$color\""])
                    }
                }
            }
        }
    }
}

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../config"
import "../services"

PanelWindow {
    id: root

    readonly property int pillWidth: 480
    readonly property int pillHeight: 100
    readonly property int contentMargin: 16
    readonly property int pillRadius: 32
    readonly property int buttonRadius: 20

    implicitWidth: pillWidth
    implicitHeight: pillHeight
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:screen-recorder"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    visible: ScreenRecorderState.open

    Shortcut {
        sequence: "Escape"
        onActivated: ScreenRecorderState.hide()
    }

    Rectangle {
        anchors.fill: parent
        color: Appearance.tooltipBg
        radius: root.pillRadius
        border.width: 0
        border.color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.1)

        RowLayout {
            anchors.fill: parent
            anchors.margins: root.contentMargin
            spacing: 12

            component RecordButton: Rectangle {
                id: btn
                property string iconTxt: ""
                property string labelTxt: ""
                property color hoverColor: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.1)
                signal clicked()

                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: root.buttonRadius
                color: mouseArea.containsMouse ? hoverColor : "transparent"

                Behavior on color { ColorAnimation { duration: 150 } }

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 4
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: btn.iconTxt
                        font.family: Appearance.fontFamily
                        font.pixelSize: 24
                        color: Theme.accent
                    }
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: btn.labelTxt
                        font.family: Appearance.fontFamily
                        font.pixelSize: 12
                        color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.6)
                    }
                }

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: btn.clicked()
                }
            }

            RecordButton {
                visible: !ScreenRecorder.recording
                iconTxt: "󰍭"
                labelTxt: "No Audio"
                onClicked: {
                    ScreenRecorder.startNoAudio()
                    ScreenRecorderState.hide()
                }
            }

            RecordButton {
                visible: !ScreenRecorder.recording
                iconTxt: "󰍬"
                labelTxt: "Mic + Audio"
                onClicked: {
                    ScreenRecorder.startMicAndAudio()
                    ScreenRecorderState.hide()
                }
            }

            RecordButton {
                visible: !ScreenRecorder.recording
                iconTxt: "󰕾"
                labelTxt: "System Audio"
                onClicked: {
                    ScreenRecorder.startSystemAudio()
                    ScreenRecorderState.hide()
                }
            }

            RecordButton {
                visible: ScreenRecorder.recording
                iconTxt: "󰓛"
                labelTxt: "Stop"
                hoverColor: Qt.rgba(1, 0.2, 0.2, 0.3)
                onClicked: {
                    ScreenRecorder.stop()
                    ScreenRecorderState.hide()
                }
            }
        }
    }
}

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

    onVisibleChanged: {
        if (root.visible) {
            root.currentIndex = 0
            Qt.callLater(() => buttonRow.forceActiveFocus())
        }
    }

    readonly property var recordActions: [
        { icon: "󰍭", label: "No Audio", action: () => ScreenRecorder.startNoAudio() },
        { icon: "󰍬", label: "Mic + Audio", action: () => ScreenRecorder.startMicAndAudio() },
        { icon: "󰕾", label: "System Audio", action: () => ScreenRecorder.startSystemAudio() }
    ]
    readonly property var stopActions: [
        { icon: "󰓛", label: "Stop", action: () => ScreenRecorder.stop(), danger: true }
    ]
    readonly property var activeActions: ScreenRecorder.recording ? root.stopActions : root.recordActions
    property int currentIndex: 0

    onActiveActionsChanged: root.currentIndex = 0

    function activate(idx) {
        if (idx < 0 || idx >= root.activeActions.length) return
        root.activeActions[idx].action()
        ScreenRecorderState.hide()
    }

    function moveSelection(delta) {
        if (root.activeActions.length === 0) return
        root.currentIndex = (root.currentIndex + delta + root.activeActions.length) % root.activeActions.length
    }

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
            id: buttonRow
            anchors.fill: parent
            anchors.margins: root.contentMargin
            spacing: 12
            focus: true

            Keys.onLeftPressed: root.moveSelection(-1)
            Keys.onRightPressed: root.moveSelection(1)
            Keys.onReturnPressed: root.activate(root.currentIndex)
            Keys.onEnterPressed: root.activate(root.currentIndex)

            component RecordButton: Rectangle {
                id: btn
                required property int index
                required property var modelData
                readonly property bool current: index === root.currentIndex
                readonly property color highlightColor: modelData.danger
                    ? Qt.rgba(1, 0.2, 0.2, 0.3)
                    : Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.18)

                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: root.buttonRadius
                color: (mouseArea.containsMouse || btn.current) ? highlightColor : "transparent"

                Behavior on color { ColorAnimation { duration: 150 } }

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 4
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: btn.modelData.icon
                        font.family: Appearance.fontFamily
                        font.pixelSize: 24
                        color: Theme.accent
                    }
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: btn.modelData.label
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
                    onEntered: root.currentIndex = btn.index
                    onClicked: root.activate(btn.index)
                }
            }

            Repeater {
                model: root.activeActions
                delegate: RecordButton {}
            }
        }
    }
}

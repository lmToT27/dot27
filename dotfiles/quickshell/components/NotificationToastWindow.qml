import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "./common"
import "../config"
import "../services"

PanelWindow {
    id: root

    readonly property int toastWidth: Appearance.controlCenterWidth * 0.75
    readonly property int autoDismissMs: 2000

    anchors { top: true; right: true }
    margins.top: Appearance.barHeight + 12
    margins.right: 0

    implicitWidth: toastWidth + 20
    implicitHeight: column.implicitHeight
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:notification-toast"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    visible: toastModel.count > 0

    ListModel { id: toastModel }

    function removeToast(toastId) {
        for (let i = 0; i < toastModel.count; i++) {
            if (String(toastModel.get(i).toastId) === String(toastId)) {
                toastModel.remove(i)
                return
            }
        }
    }

    Connections {
        target: NotificationHistory
        function onNotified(entry) {
            if (NotificationHistory.dnd) return
            toastModel.insert(0, {
                toastId: entry.id,
                appName: entry.appName,
                summary: entry.summary,
                body: entry.body
            })
        }
    }

    Column {
        id: column
        width: root.width
        spacing: 8

        move: Transition {
            NumberAnimation { properties: "y"; duration: Appearance.animMedium; easing.type: Easing.OutCubic }
        }

        Repeater {
            model: toastModel

            delegate: Item {
                id: toastWrapper
                required property int index
                required property string toastId
                required property string appName
                required property string summary
                required property string body

                width: root.width
                height: container.height
                clip: true

                Component.onCompleted: enterAnim.start()

                function dismiss(alreadyOffscreen) {
                    dismissTimer.stop()
                    if (alreadyOffscreen) {
                        collapseAnim.start()
                    } else {
                        slideOutThenCollapseAnim.start()
                    }
                }

                Rectangle {
                    id: container
                    width: root.toastWidth
                    height: Math.max(50, toastContent.implicitHeight + 16)
                    x: 0
                    radius: Appearance.controlCenterCornerRadius
                    color: Appearance.tooltipBg
                    clip: true

                    RowLayout {
                        id: toastContent
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.margins: 8
                        spacing: 10

                        Rectangle {
                            Layout.preferredWidth: 28
                            Layout.preferredHeight: 28
                            Layout.alignment: Qt.AlignTop
                            radius: width / 2
                            color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.18)

                            Text {
                                anchors.centerIn: parent
                                text: "󰂚"
                                font.family: Appearance.fontFamily
                                font.pixelSize: 14
                                color: Theme.accent
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            Text {
                                Layout.fillWidth: true
                                text: toastWrapper.appName
                                font.family: Appearance.fontFamily
                                font.pixelSize: 10
                                color: Qt.rgba(1, 1, 1, 0.5)
                                elide: Text.ElideRight
                            }

                            Text {
                                Layout.fillWidth: true
                                text: toastWrapper.summary
                                font.family: Appearance.fontFamily
                                font.bold: true
                                font.pixelSize: 13
                                color: "white"
                                elide: Text.ElideRight
                            }

                            Text {
                                Layout.fillWidth: true
                                text: toastWrapper.body
                                font.family: Appearance.fontFamily
                                font.pixelSize: 11
                                color: Qt.rgba(1, 1, 1, 0.55)
                                wrapMode: Text.WordWrap
                                maximumLineCount: 2
                                elide: Text.ElideRight
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        preventStealing: true
                    }
                }

                ParallelAnimation {
                    id: enterAnim
                    NumberAnimation { target: container; property: "x"; from: root.width; to: 0; duration: Appearance.animMedium; easing.type: Easing.OutCubic }
                    NumberAnimation { target: toastWrapper; property: "opacity"; from: 0; to: 1; duration: Appearance.animMedium; easing.type: Easing.OutCubic }
                }

                SequentialAnimation {
                    id: slideOutThenCollapseAnim
                    ParallelAnimation {
                        NumberAnimation { target: container; property: "x"; to: root.width; duration: Appearance.animMedium; easing.type: Easing.OutCubic }
                        NumberAnimation { target: toastWrapper; property: "opacity"; to: 0; duration: Appearance.animMedium; easing.type: Easing.OutCubic }
                    }
                    NumberAnimation { target: toastWrapper; property: "height"; to: 0; duration: Appearance.animFast; easing.type: Easing.OutCubic }
                    onFinished: root.removeToast(toastWrapper.toastId)
                }

                ParallelAnimation {
                    id: collapseAnim
                    NumberAnimation { target: container; property: "opacity"; to: 0; duration: Appearance.animFast; easing.type: Easing.OutCubic }
                    NumberAnimation { target: toastWrapper; property: "height"; to: 0; duration: Appearance.animFast; easing.type: Easing.OutCubic }
                    onFinished: root.removeToast(toastWrapper.toastId)
                }

                Timer {
                    id: dismissTimer
                    interval: root.autoDismissMs
                    running: true
                    onTriggered: toastWrapper.dismiss(false)
                }
            }
        }
    }
}

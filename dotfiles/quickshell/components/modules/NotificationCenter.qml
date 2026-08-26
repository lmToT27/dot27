import QtQuick
import QtQuick.Layouts
import Quickshell
import "../common"
import "../../config"
import "../../services"

HoverIcon {
    id: root

    text: NotificationHistory.dnd ? "󰂛"
        : NotificationHistory.unreadCount > 0 ? "󱅫" : "󰂚"

    onClicked: {
        panel.visible = !panel.visible
        if (panel.visible) NotificationHistory.markAllRead()
    }
    onRightClicked: NotificationHistory.toggleDnd()

    // Real separate popup surface — see StyledTooltip.qml for why (the
    // bar's own PanelWindow surface is clipped to barHeight, so a plain
    // child Item can't render below it). Anchored to the bottom-right
    // corner of the icon, expanding down-left to stay right-aligned.
    PopupWindow {
        id: panel
        anchor.item: root
        anchor.edges: Edges.Bottom | Edges.Right
        anchor.gravity: Edges.Bottom | Edges.Left
        anchor.margins.top: 8
        visible: false
        implicitWidth: 300
        implicitHeight: Math.min(360, list.contentHeight + 24)
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            radius: Appearance.radiusOuter
            color: Appearance.tooltipBg

            ListView {
                id: list
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8
                clip: true
                model: NotificationHistory.history

                delegate: ColumnLayout {
                    id: entry
                    required property var modelData
                    width: list.width
                    spacing: 2

                    Text {
                        Layout.fillWidth: true
                        text: entry.modelData.appName + " — " + entry.modelData.summary
                        color: Theme.accent
                        font.bold: true
                        font.family: Appearance.fontFamily
                        wrapMode: Text.Wrap
                    }
                    Text {
                        Layout.fillWidth: true
                        visible: entry.modelData.body.length > 0
                        text: entry.modelData.body
                        color: "#ecc6d9"
                        wrapMode: Text.Wrap
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                visible: list.count === 0
                text: "Không có thông báo"
                color: Theme.accent
                font.family: Appearance.fontFamily
            }
        }
    }
}

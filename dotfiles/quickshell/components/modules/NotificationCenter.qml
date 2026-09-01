import QtQuick
import QtQuick.Layouts
import "../common"
import "../../config"
import "../../services"

// Notification Center's content: header (title + DND + Clear All) and a
// scrolling list of notification cards, with a centered empty state. Pure
// content Item, embedded by NotificationCenterWindow.qml which owns the
// actual surface, slide animation, and corner shaping.
//
// Backed by the NotificationHistory singleton, which doesn't capture a
// per-app icon today, so cards fall back to a generic bell glyph.
Item {
    id: root
    implicitHeight: 420

    ColumnLayout {
        anchors.fill: parent
        spacing: 14

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: NotificationHistory.history.length > 0
                    ? "Notifications • " + NotificationHistory.history.length
                    : "Notifications"
                font.family: Appearance.fontFamily
                font.bold: true
                font.pixelSize: 18
                font.capitalization: Font.AllUppercase
                font.letterSpacing: 1.5
                color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.8)
            }

            Item { Layout.fillWidth: true }

            // DND toggle — reads/writes NotificationHistory.dnd directly so
            // this stays in sync with the topbar bell's right-click toggle
            // instead of tracking a second, divergent flag.
            Rectangle {
                id: dndButton
                readonly property bool isDnd: NotificationHistory.dnd

                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                radius: Appearance.radiusInner
                color: isDnd ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.18) : Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.06)
                scale: dndMouseArea.pressed ? 0.95 : 1
                Behavior on color { ColorAnimation { duration: Appearance.animFast } }
                Behavior on scale { NumberAnimation { duration: Appearance.animFast } }

                Text {
                    anchors.centerIn: parent
                    text: dndButton.isDnd ? "󰂛" : "󰂚"
                    font.family: Appearance.fontFamily
                    font.pixelSize: 15
                    color: dndButton.isDnd ? Theme.accent : Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.5)
                    Behavior on color { ColorAnimation { duration: Appearance.animFast } }
                }

                MouseArea {
                    id: dndMouseArea
                    anchors.fill: parent
                    onClicked: NotificationHistory.toggleDnd()
                }
            }

            // Destructive-action tint on hover/press since this wipes the whole history.
            Rectangle {
                id: clearAllButton
                radius: height / 2
                implicitWidth: clearAllLabel.implicitWidth + 20
                implicitHeight: 32
                color: clearMouseArea.pressed
                    ? Qt.rgba(Appearance.critical.r, Appearance.critical.g, Appearance.critical.b, 0.28)
                    : clearMouseArea.containsMouse
                        ? Qt.rgba(Appearance.critical.r, Appearance.critical.g, Appearance.critical.b, 0.16)
                        : Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.08)
                scale: clearMouseArea.pressed ? 0.95 : 1
                Behavior on color { ColorAnimation { duration: Appearance.animFast } }
                Behavior on scale { NumberAnimation { duration: Appearance.animFast } }

                Text {
                    id: clearAllLabel
                    anchors.centerIn: parent
                    text: "Clear All"
                    font.family: Appearance.fontFamily
                    font.bold: true
                    font.pixelSize: 12
                    color: (clearMouseArea.pressed || clearMouseArea.containsMouse) ? Appearance.critical : Theme.fg
                    Behavior on color { ColorAnimation { duration: Appearance.animFast } }
                }

                MouseArea {
                    id: clearMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        if (list.count > 0 && !clearAllAnimation.running)
                            clearAllAnimation.start()
                    }
                }
            }
        }

        // Fills the remaining space below the header with either the list
        // or the centered empty state, never both.
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ColumnLayout {
                anchors.centerIn: parent
                visible: NotificationHistory.history.length === 0
                opacity: 0.3
                spacing: 8

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "󰒲"
                    font.family: Appearance.fontFamily
                    font.pixelSize: 64
                    color: Theme.fg
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "No notifications"
                    font.family: Appearance.fontFamily
                    font.pixelSize: 12
                    color: Theme.fg
                }
            }

            ListView {
                id: list
                anchors.fill: parent
                visible: NotificationHistory.history.length > 0
                clip: true
                spacing: 12
                model: NotificationHistory.history

                // A separate Translate instead of animating x directly —
                // list is anchors.fill'd, so an animation writing straight
                // to x fights the anchor's own binding on it.
                transform: Translate { id: listSlide; x: 0 }

                // history is a plain JS array, not a ListModel — delegates
                // read fields via `modelData`, not per-key `model.<role>`.
                delegate: NotificationCard {
                    width: list.width
                    icon: "󰂚"
                    appName: modelData.appName
                    summary: modelData.summary
                    body: modelData.body
                    onClosed: NotificationHistory.dismiss(modelData.id)
                }
            }

            SequentialAnimation {
                id: clearAllAnimation

                ParallelAnimation {
                    NumberAnimation {
                        target: list; property: "opacity"
                        to: 0; duration: 250; easing.type: Easing.OutCubic
                    }
                    NumberAnimation {
                        target: listSlide; property: "x"
                        to: 50; duration: 250; easing.type: Easing.OutCubic
                    }
                }

                ScriptAction { script: NotificationHistory.clear() }

                PropertyAction { target: listSlide; property: "x"; value: 0 }
                PropertyAction { target: list; property: "opacity"; value: 1 }
            }
        }
    }
}

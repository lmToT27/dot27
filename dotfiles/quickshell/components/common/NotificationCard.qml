import QtQuick
import QtQuick.Layouts
import "../../config"
import "../../services"

// A single notification entry inside NotificationCenter's ListView.
// Two layers: a fixed trash-reveal background (root itself) and a
// draggable `cardContent` on top holding the actual card UI — dragging
// cardContent right past 40% of its width fires `closed()` (same signal
// the corner X button uses), short of that it springs back to x:0.
Item {
    id: root

    property string icon: ""
    property string appName: ""
    property string summary: ""
    property string body: ""
    // Faint lightening reads as "a card among cards" on the sidebar's own
    // black panel. NotificationToastWindow overrides this to "transparent"
    // since its own solid-black backdrop already supplies that fill.
    property color contentColor: Qt.rgba(1, 1, 1, 0.06)
    signal closed()

    implicitHeight: cardContent.height

    // Trash-reveal layer, stays put underneath. Faded by drag progress so
    // it stays fully hidden until actually swiped (cardContent's own fill
    // is translucent, so it'd otherwise show through at rest).
    Rectangle {
        id: deleteBackground
        anchors.fill: parent
        radius: Appearance.radiusOuter
        color: Qt.rgba(Appearance.critical.r, Appearance.critical.g, Appearance.critical.b, 0.25)
        opacity: root.width > 0 ? Math.min(1, cardContent.x / (root.width * 0.4)) : 0

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 20
            anchors.verticalCenter: parent.verticalCenter
            text: "󰆴"
            font.family: Appearance.fontFamily
            font.pixelSize: 18
            color: Appearance.critical
        }
    }

    Rectangle {
        id: cardContent
        x: 0
        width: root.width
        height: Math.max(64, textColumn.implicitHeight + 24)
        radius: Appearance.radiusOuter
        color: root.contentColor
        opacity: root.width > 0 ? 1 - (cardContent.x / root.width) : 1

        // preventStealing so the ListView's vertical Flickable doesn't
        // grab this horizontal drag mid-gesture. Declared before the
        // RowLayout/closeButton so their own MouseAreas still win clicks.
        MouseArea {
            id: dragArea
            anchors.fill: parent
            drag.target: cardContent
            drag.axis: Drag.XAxis
            drag.minimumX: 0
            drag.maximumX: root.width
            preventStealing: true

            onReleased: {
                const threshold = root.width * 0.4
                if (cardContent.x > threshold) {
                    dismissAnim.start()
                } else {
                    snapBackAnim.start()
                }
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 12
            anchors.rightMargin: 32
            spacing: 10

            // Circular icon badge, accent-tinted.
            Rectangle {
                Layout.preferredWidth: 36
                Layout.preferredHeight: 36
                Layout.alignment: Qt.AlignTop
                radius: width / 2
                color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.18)

                Text {
                    anchors.centerIn: parent
                    text: root.icon
                    font.family: Appearance.fontFamily
                    font.pixelSize: 16
                    color: Theme.accent
                }
            }

            ColumnLayout {
                id: textColumn
                Layout.fillWidth: true
                spacing: 2

                // App name — least prominent line; summary carries the message.
                Text {
                    Layout.fillWidth: true
                    text: root.appName
                    font.family: Appearance.fontFamily
                    font.pixelSize: 10
                    color: Qt.rgba(1, 1, 1, 0.5)
                    elide: Text.ElideRight
                }

                // Summary — the most prominent line in the card.
                Text {
                    Layout.fillWidth: true
                    text: root.summary
                    font.family: Appearance.fontFamily
                    font.bold: true
                    font.pixelSize: 14
                    color: "white"
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    text: root.body
                    font.family: Appearance.fontFamily
                    font.pixelSize: 11
                    color: Qt.rgba(1, 1, 1, 0.55)
                    wrapMode: Text.WordWrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }
            }
        }

        Text {
            id: closeButton
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: 8
            text: "󰅖"
            font.family: Appearance.fontFamily
            font.pixelSize: 12
            color: Qt.rgba(1, 1, 1, closeMouseArea.containsMouse ? 0.85 : 0.4)
            Behavior on color { ColorAnimation { duration: Appearance.animFast } }
            scale: closeMouseArea.pressed ? 0.9 : 1
            Behavior on scale { NumberAnimation { duration: Appearance.animFast } }

            MouseArea {
                id: closeMouseArea
                anchors.fill: parent
                anchors.margins: -6
                hoverEnabled: true
                onClicked: root.closed()
            }
        }
    }

    // deleteBackground's opacity binding caps at 1 well before cardContent
    // finishes sliding off, so it's explicitly animated to 0 here too
    // (overriding the live binding) to avoid a leftover red flash.
    ParallelAnimation {
        id: dismissAnim
        NumberAnimation { target: cardContent; property: "x"; to: root.width; duration: 150; easing.type: Easing.OutCubic }
        NumberAnimation { target: deleteBackground; property: "opacity"; to: 0; duration: 120; easing.type: Easing.OutCubic }
        onFinished: root.closed()
    }

    NumberAnimation {
        id: snapBackAnim
        target: cardContent
        property: "x"
        to: 0
        duration: 400
        easing.type: Easing.OutBounce
    }
}

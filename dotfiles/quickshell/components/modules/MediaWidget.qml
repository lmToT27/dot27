import QtQuick
import "../common"
import "../../config"
import "../../services"

Item {
    id: root

    readonly property string label: Mpris.title + (Mpris.artist ? " — " + Mpris.artist : "")
    readonly property string displayText: Mpris.hasMedia ? label : "No Media"
    readonly property string icon: Mpris.hasMedia
        ? (Mpris.status === "Playing" ? "\u{F001}" : "\u{F04C}")
        : "\u{F04D}"
    readonly property int maxTextWidth: 140

    readonly property bool hovered: mouseArea.containsMouse
    readonly property color contentColor: hovered ? Theme.accentContrast : Theme.accent
    property bool infoOpen: false

    implicitWidth: Math.round(row.implicitWidth + Appearance.paddingH)
    implicitHeight: Math.round(Math.max(row.implicitHeight, 20))

    Rectangle {
        anchors.fill: parent
        radius: Appearance.radiusInner + 2
        color: root.hovered ? Theme.accent : "transparent"
        Behavior on color { ColorAnimation { duration: Appearance.animMedium } }
    }

    Row {
        id: row
        x: Math.round((parent.width - width) / 2)
        y: Math.round((parent.height - height) / 2)
        spacing: 6

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.icon
            font.family: Appearance.fontFamily
            font.pixelSize: Appearance.fontSize
            font.bold: true
            color: root.contentColor
            Behavior on color { ColorAnimation { duration: Appearance.animMedium } }
        }

        Item {
            id: viewport
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(root.maxTextWidth, title1.implicitWidth)
            height: title1.implicitHeight
            clip: true

            readonly property bool needsScroll: title1.implicitWidth > root.maxTextWidth
            readonly property bool scrolling: needsScroll && Mpris.status === "Playing"
            readonly property real scrollDistance: title1.implicitWidth + scrollRow.spacing

            Row {
                id: scrollRow
                spacing: 40

                Text {
                    id: title1
                    text: root.displayText
                    font.family: Appearance.fontFamily
                    font.pixelSize: Appearance.fontSize
                    font.bold: true
                    color: root.contentColor
                    Behavior on color { ColorAnimation { duration: Appearance.animMedium } }
                    onTextChanged: scrollRow.x = 0
                }

                Text {
                    visible: viewport.needsScroll
                    text: title1.text
                    font: title1.font
                    color: title1.color
                }

                NumberAnimation {
                    id: marquee
                    target: scrollRow
                    property: "x"
                    from: 0
                    to: -viewport.scrollDistance
                    duration: viewport.scrollDistance * 30
                    loops: Animation.Infinite
                    running: viewport.scrolling
                    onRunningChanged: if (!running) scrollRow.x = 0
                }
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        anchors.margins: -4
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) root.infoOpen = !root.infoOpen
            else Mpris.playPause()
        }
    }

    StyledTooltip {
        anchorItem: root
        panelOpen: Mpris.hasMedia && root.infoOpen
        text: root.label
        onDismissed: root.infoOpen = false
    }
}

import QtQuick
import "../../config"
import "../../services"

Item {
    id: root

    property string text: ""
    property color textColor: Theme.accent
    property bool invertOnHover: true
    property bool blinking: false
    property bool tooltip: false
    property string tooltipText: ""

    readonly property bool hovered: mouseArea.containsMouse
    // Right-click toggles the info tooltip open/closed instead of hover,
    // since hover kept getting clipped/overlapped by the bar itself.
    property bool infoOpen: false

    signal clicked()
    signal rightClicked()

    implicitWidth: Math.round(label.implicitWidth + Appearance.paddingH)
    implicitHeight: Math.round(Math.max(label.implicitHeight, 20))

    Rectangle {
        anchors.fill: parent
        anchors.margins: 0
        radius: Appearance.radiusInner + 2
        color: root.invertOnHover && root.hovered ? Theme.accent : "transparent"
        Behavior on color { ColorAnimation { duration: Appearance.animMedium } }
    }

    Text {
        id: label
        x: Math.round((parent.width - width) / 2)
        y: Math.round((parent.height - height) / 2)
        text: root.text
        font.family: Appearance.fontFamily
        font.pixelSize: Appearance.fontSize
        font.bold: true
        color: root.invertOnHover && root.hovered ? "black" : root.textColor
        Behavior on color { ColorAnimation { duration: Appearance.animMedium } }

        SequentialAnimation on opacity {
            running: root.blinking
            loops: Animation.Infinite
            NumberAnimation { to: 0.5; duration: 500 }
            NumberAnimation { to: 1.0; duration: 500 }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        anchors.margins: -4
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) {
                root.infoOpen = !root.infoOpen
                root.rightClicked()
            } else {
                root.clicked()
            }
        }
    }

    StyledTooltip {
        anchorItem: root
        visible: root.tooltip && root.infoOpen && root.tooltipText.length > 0
        text: root.tooltipText
    }
}

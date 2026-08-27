import QtQuick
import "../../config"
import "../../services"

Item {
    id: root

    property string text: ""
    property int fontSize: Appearance.fontSize
    property color textColor: Theme.accent
    property bool invertOnHover: true
    property bool blinking: false
    property bool tooltip: false
    property string tooltipText: ""
    property color borderColor: "transparent"
    property int borderWidth: 0
    // Floors the label width so a glyph-swapping button (e.g. DND bell)
    // doesn't resize the bar pill on every click. 0 = no floor.
    property int minContentWidth: 0

    readonly property bool hovered: mouseArea.containsMouse
    // Right-click toggles the info tooltip instead of hover, which gets
    // clipped/overlapped by the bar itself.
    property bool infoOpen: false

    signal clicked()

    implicitWidth: Math.round(Math.max(label.implicitWidth, minContentWidth) + Appearance.paddingH)
    implicitHeight: Math.round(Math.max(label.implicitHeight, 20))

    Rectangle {
        anchors.fill: parent
        anchors.margins: 0
        radius: Appearance.radiusInner + 2
        color: root.invertOnHover && root.hovered ? Theme.accent : "transparent"
        border.color: root.borderColor
        border.width: root.borderWidth
        Behavior on color { ColorAnimation { duration: Appearance.animMedium } }
    }

    Text {
        id: label
        x: Math.round((parent.width - width) / 2)
        y: Math.round((parent.height - height) / 2)
        text: root.text
        font.family: Appearance.fontFamily
        font.pixelSize: root.fontSize
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
        pressAndHoldInterval: 400

        // Qt still emits clicked() on release after a pressAndHold fires, so
        // this flag consumes that trailing click instead of double-firing.
        property bool suppressClick: false

        onPressed: suppressClick = false
        onPressAndHold: mouse => {
            if (mouse.button !== Qt.LeftButton) return
            suppressClick = true
        }
        onClicked: mouse => {
            if (suppressClick) {
                suppressClick = false
                return
            }
            if (mouse.button === Qt.RightButton) {
                root.infoOpen = !root.infoOpen
            } else {
                root.clicked()
            }
        }
    }

    StyledTooltip {
        anchorItem: root
        panelOpen: root.tooltip && root.infoOpen && root.tooltipText.length > 0
        text: root.tooltipText
        onDismissed: root.infoOpen = false
    }
}

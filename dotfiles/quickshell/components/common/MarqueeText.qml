import QtQuick
import "../../services"

// Auto-scrolling text: stays still while it fits the given width, only
// loops once the text is actually wider than that.
Item {
    id: root

    property string text: ""
    property alias font: label1.font
    property color color: Theme.fg
    // Scrolling only runs while this is true (e.g. "is actually playing").
    property bool active: true

    readonly property real gap: 40
    readonly property bool needsScroll: label1.implicitWidth > root.width
    readonly property bool scrolling: root.needsScroll && root.active

    implicitHeight: label1.implicitHeight
    clip: true

    Row {
        id: scrollRow
        spacing: root.gap

        Text {
            id: label1
            text: root.text
            color: root.color
            onTextChanged: scrollRow.x = 0
        }

        // Trailing copy for a seamless loop — only present once needed.
        Text {
            visible: root.needsScroll
            text: label1.text
            font: label1.font
            color: label1.color
        }

        NumberAnimation {
            target: scrollRow
            property: "x"
            from: 0
            to: -(label1.implicitWidth + scrollRow.spacing)
            duration: (label1.implicitWidth + scrollRow.spacing) * 30
            loops: Animation.Infinite
            running: root.scrolling
            onRunningChanged: if (!running) scrollRow.x = 0
        }
    }
}

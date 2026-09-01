import QtQuick
import QtQuick.Layouts
import "../../config"
import "../../services"

// Hand-rolled horizontal slider (drag or tap-anywhere-on-track) used for
// Control Center's volume/brightness rows.
RowLayout {
    id: root

    property string icon: ""
    property int value: 0
    // Set when the underlying toggle (e.g. AudioService.muted) is "off" —
    // dims the icon instead of needing a second icon glyph per state.
    property bool dimmed: false
    signal moved(int pct)
    signal iconClicked()

    spacing: 14

    // Fixed-width icon column so a wider glyph in one instance can't shift
    // where its track starts — keeps Volume/Brightness sliders aligned.
    Item {
        Layout.preferredWidth: 30
        Layout.preferredHeight: iconText.implicitHeight

        Text {
            id: iconText
            anchors.centerIn: parent
            text: root.icon
            color: Theme.accent
            opacity: root.dimmed ? 0.4 : 1
            font.pixelSize: 15
            font.family: Appearance.fontFamily
        }

        MouseArea { anchors.fill: parent; anchors.margins: -4; onClicked: root.iconClicked() }
    }

    Rectangle {
        id: track
        Layout.fillWidth: true
        // Pill-shaped, thick enough to read as a real control surface.
        height: 14
        radius: height / 2
        color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.15)

        Rectangle {
            height: parent.height
            radius: parent.radius
            color: Theme.accent
            width: parent.width * (root.value / 100)
        }

        MouseArea {
            anchors.fill: parent
            anchors.margins: -6

            function updateFromX(x) {
                const pct = Math.max(0, Math.min(100, Math.round((x / track.width) * 100)))
                root.moved(pct)
            }

            onPressed: mouse => updateFromX(mouse.x)
            onPositionChanged: mouse => { if (pressed) updateFromX(mouse.x) }
        }
    }

    Text {
        text: root.value + "%"
        color: Theme.fg
        font.family: Appearance.fontFamily
        font.weight: Font.DemiBold
        Layout.preferredWidth: 34
        Layout.leftMargin: 2
        horizontalAlignment: Text.AlignRight
    }
}

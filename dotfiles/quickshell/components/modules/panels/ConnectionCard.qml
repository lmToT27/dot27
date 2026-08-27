import QtQuick
import QtQuick.Layouts
import "../../../config"
import "../../../services"

// Tier 1's right column: a Wi-Fi/Bluetooth status row (icon + a two-line
// title/status column), used twice stacked in ControlCenter. Click toggles
// the radio; long-press bubbles up to launch that protocol's management
// GUI as a niri floating window (see ControlCenter.qml's onLongPressed).
Rectangle {
    id: root

    property string icon: ""
    property string title: ""
    property string subtitle: ""
    property bool active: false
    signal toggled()
    signal longPressed()

    // Fallback default — ControlCenter.qml overrides this per-instance so
    // both cards' combined height matches FocusTimer's exactly.
    Layout.fillWidth: true
    Layout.preferredHeight: 44
    radius: Appearance.radiusInner
    color: root.active ? Theme.accent : Qt.rgba(1, 1, 1, 0.04)
    Behavior on color { ColorAnimation { duration: Appearance.animFast } }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 8

        // Fixed-width icon column (same fix as SliderRow's icon wrapper)
        // — the Wi-Fi and Bluetooth glyphs don't share the same advance
        // width, so without a shared floor here the title/subtitle column
        // below starts at a different X in each of the two stacked cards.
        Text {
            Layout.preferredWidth: 20
            Layout.alignment: Qt.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            text: root.icon
            font.family: Appearance.fontFamily
            font.pixelSize: 18
            color: root.active ? Theme.onAccent : Qt.rgba(1, 1, 1, 0.4)
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 1

            Text {
                Layout.fillWidth: true
                text: root.title
                font.family: Appearance.fontFamily
                font.bold: true
                font.pixelSize: 12
                color: root.active ? Theme.onAccent : "white"
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                text: root.subtitle
                font.family: Appearance.fontFamily
                font.pixelSize: 10
                color: root.active ? Qt.rgba(Theme.onAccent.r, Theme.onAccent.g, Theme.onAccent.b, 0.65) : Qt.rgba(1, 1, 1, 0.55)
                elide: Text.ElideRight
            }
        }
    }

    MouseArea {
        anchors.fill: parent

        property bool suppressClick: false

        onPressed: suppressClick = false
        onPressAndHold: {
            suppressClick = true
            root.longPressed()
        }
        onClicked: {
            if (suppressClick) {
                suppressClick = false
                return
            }
            root.toggled()
        }
    }
}

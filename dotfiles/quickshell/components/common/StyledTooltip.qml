import QtQuick
import Quickshell
import "../../config"
import "../../services"

// A real separate popup surface (not a child Item) — the bar's own
// PanelWindow surface is exactly barHeight tall, so anything drawn past
// that edge as a plain child Item gets clipped by the Wayland surface
// itself, no matter how it's positioned. PopupWindow gets its own
// correctly-sized surface anchored below the triggering item instead.
PopupWindow {
    id: root

    property string text: ""
    property Item anchorItem: null

    anchor.item: anchorItem
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    anchor.margins.top: 8

    implicitWidth: label.implicitWidth + Appearance.paddingH * 2
    implicitHeight: label.implicitHeight + Appearance.paddingV * 2
    color: "transparent"

    Rectangle {
        anchors.fill: parent
        radius: Appearance.radiusInner
        color: Appearance.tooltipBg

        Text {
            id: label
            anchors.centerIn: parent
            text: root.text
            color: Theme.accent
            font.family: Appearance.fontFamily
            font.bold: true
        }
    }
}

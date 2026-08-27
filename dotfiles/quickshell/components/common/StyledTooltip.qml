import QtQuick
import Quickshell
import "../../config"
import "../../services"

// A real separate popup surface — the bar's PanelWindow is clipped to
// barHeight, so a plain child Item can't render past that edge.
PopupWindow {
    id: root

    property string text: ""
    property Item anchorItem: null
    property bool panelOpen: false

    // Auto-dismisses on outside click. Deliberately does NOT write
    // root.panelOpen here: HoverIcon binds it declaratively, and an
    // imperative write would permanently destroy that binding.
    signal dismissed()
    grabFocus: true
    onClosed: root.dismissed()

    // Keeps the surface alive through the fade-out instead of cutting it short.
    onPanelOpenChanged: {
        if (panelOpen) {
            root.visible = true
        } else {
            closeTimer.restart()
        }
    }

    Timer {
        id: closeTimer
        interval: Appearance.animFast
        onTriggered: root.visible = false
    }

    anchor.item: anchorItem
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    anchor.margins.top: 8

    implicitWidth: label.implicitWidth + Appearance.paddingH * 2
    implicitHeight: label.implicitHeight + Appearance.paddingV * 2
    visible: false
    color: "transparent"

    Rectangle {
        anchors.fill: parent
        radius: Appearance.radiusInner
        color: Appearance.tooltipBg
        opacity: root.panelOpen ? 1 : 0

        Behavior on opacity {
            NumberAnimation { duration: Appearance.animFast; easing.type: Easing.OutCubic }
        }

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

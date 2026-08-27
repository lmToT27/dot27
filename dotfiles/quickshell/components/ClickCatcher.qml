import QtQuick
import Quickshell
import Quickshell.Wayland

// Fullscreen, invisible-until-active layer-shell surface that dismisses a
// panel on any outside click — ControlCenterWindow/NotificationCenterWindow
// are plain top-level layer-shell surfaces (not xdg_popups), so they have
// no dismiss-on-outside-click of their own.
PanelWindow {
    id: root

    property bool active: false
    signal dismissRequested()

    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    // Deliberately NOT `visible: active` — mapping a new layer-shell surface
    // the same tick as another one opening has previously lost a race in
    // niri's surface-commit handling and broken the other surface's render.
    // Deferring by one frame is cheap, imperceptible insurance.
    visible: false
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.namespace: "quickshell:click-catcher"

    onActiveChanged: {
        if (active) mapDelay.start()
        else { mapDelay.stop(); root.visible = false }
    }

    Timer {
        id: mapDelay
        interval: 32
        onTriggered: if (root.active) root.visible = true
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.dismissRequested()
    }
}

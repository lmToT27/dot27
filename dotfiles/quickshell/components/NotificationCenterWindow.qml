import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import "./modules"
import "../config"
import "../services"

// Notification Center's own standalone surface: a right-edge sidebar,
// vertically centered, activated via the Mod+N -> IPC keybind (see
// NotificationCenterState) — mirrors ControlCenterWindow.qml, flipped to
// the opposite screen edge.
PanelWindow {
    id: root

    readonly property int panelWidth: Appearance.controlCenterWidth
    readonly property int contentMargin: 16
    readonly property int morphDuration: 350

    readonly property bool panelOpen: NotificationCenterState.open

    // Mirror of ControlCenterWindow's leftDrip/rightRadius: the RIGHT edge
    // is flush against the screen (drip lives there), LEFT floats free
    // with an ordinary rounded corner.
    readonly property real flushDrip: Appearance.radiusOuter
    readonly property real floatingRadius: Appearance.controlCenterCornerRadius
    readonly property real bodyHeight: content.implicitHeight + contentMargin * 2

    // Anchoring only `right` centers vertically for free (per wlr-layer-shell
    // rule: an axis with neither edge anchored is centered on that axis).
    anchors.right: true

    implicitWidth: panelWidth
    implicitHeight: bodyHeight + flushDrip * 2
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    // Overlay, not Top: same reasoning as ControlCenterWindow — the
    // ClickCatcher scrim is also on this layer and would otherwise win
    // the stacking order and swallow clicks meant for this panel.
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:notification-center"

    // Real surface only maps while open (or animating closed, see
    // closeTimer) — same reasoning as ControlCenterWindow.
    visible: false

    onPanelOpenChanged: {
        if (panelOpen) {
            root.visible = true
            // Opening the panel is the "I've seen these" signal — matches
            // the old pre-migration popup's mark-read-on-open behavior.
            NotificationHistory.markAllRead()
        } else {
            closeTimer.restart()
        }
    }

    Timer {
        id: closeTimer
        interval: root.morphDuration
        // Guards against a reopen landing mid-close: if the panel was
        // reopened while this stale timer was still counting down from a
        // previous close, panelOpen is true again by the time this fires
        // and the surface must stay mapped.
        onTriggered: if (!root.panelOpen) root.visible = false
    }

    Item {
        id: clipArea
        anchors.fill: parent
        clip: true

        Item {
            id: card
            width: root.panelWidth
            height: parent.height
            // Closed: slid one full width past the right edge, already
            // outside this surface's bounds — clip above is just a safety
            // net for the drip curve at the settled ends of the animation.
            x: root.panelOpen ? 0 : root.panelWidth

            Behavior on x {
                NumberAnimation { duration: root.morphDuration; easing.type: Easing.OutExpo }
            }

            Shape {
                id: background
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer

                // Flush right edge, top and bottom flowing into it via a
                // drip; left edge gets an ordinary rounded corner — mirror
                // of ControlCenterWindow's outline, reflected around bgW.
                ShapePath {
                    id: outline
                    fillColor: Appearance.tooltipBg
                    strokeWidth: -1

                    readonly property real d: root.flushDrip
                    readonly property real fr: root.floatingRadius
                    readonly property real bgW: background.width
                    readonly property real bgH: root.bodyHeight

                    startX: outline.bgW; startY: 0

                    // Top-right drip: mirror of ControlCenterWindow's
                    // top-left drip, reflected around bgW.
                    PathCubic {
                        control1X: outline.bgW; control1Y: outline.d * 0.5
                        control2X: outline.bgW - outline.d * 0.5; control2Y: outline.d
                        x: outline.bgW - outline.d; y: outline.d
                    }

                    // Top edge, then an ordinary rounded corner on the
                    // floating left side.
                    PathLine { x: outline.fr; y: outline.d }

                    PathCubic {
                        control1X: outline.fr * 0.5; control1Y: outline.d
                        control2X: 0; control2Y: outline.d + outline.fr * 0.5
                        x: 0; y: outline.d + outline.fr
                    }

                    PathLine { x: 0; y: outline.d + outline.bgH - outline.fr }

                    PathCubic {
                        control1X: 0; control1Y: outline.d + outline.bgH - outline.fr * 0.5
                        control2X: outline.fr * 0.5; control2Y: outline.d + outline.bgH
                        x: outline.fr; y: outline.d + outline.bgH
                    }

                    PathLine { x: outline.bgW - outline.d; y: outline.d + outline.bgH }

                    // Bottom-right drip: mirror of ControlCenterWindow's
                    // bottom-left drip, reflected around bgW.
                    PathCubic {
                        control1X: outline.bgW - outline.d * 0.5; control1Y: outline.d + outline.bgH
                        control2X: outline.bgW; control2Y: outline.d + outline.bgH + outline.d * 0.5
                        x: outline.bgW; y: outline.d + outline.bgH + outline.d
                    }

                    PathLine { x: outline.bgW; y: 0 }
                }
            }

            NotificationCenter {
                id: content
                anchors.fill: parent
                anchors.margins: root.contentMargin
                anchors.topMargin: root.contentMargin + root.flushDrip
                anchors.bottomMargin: root.contentMargin + root.flushDrip
                // Mirrors ControlCenterWindow's opacity choreography.
                opacity: root.panelOpen ? 1 : 0
                Behavior on opacity {
                    SequentialAnimation {
                        PauseAnimation { duration: root.panelOpen ? root.morphDuration / 2 : 0 }
                        NumberAnimation { duration: root.morphDuration / 2; easing.type: Easing.OutCubic }
                    }
                }
            }
        }
    }
}

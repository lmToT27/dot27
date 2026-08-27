import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import "./modules"
import "../config"
import "../services"

// Control Center's own standalone surface: a left-edge sidebar, vertically
// centered, activated purely via the Mod+M -> IPC keybind (see
// ControlCenterState) — a plain top-level layer-shell PanelWindow, not an
// xdg_popup, so none of the popup grab/race bugs apply.
PanelWindow {
    id: root

    readonly property int panelWidth: Appearance.controlCenterWidth
    readonly property int contentMargin: 16
    // Full open/close cycle length; the fade is a half-length animation
    // nested inside it (delayed on open, upfront on close).
    readonly property int morphDuration: 350

    readonly property bool panelOpen: ControlCenterState.open

    // Fluid drip corner treatment (see BarPill) at both left corners, since
    // this sidebar floats vertically centered and both are exposed.
    readonly property real leftDrip: Appearance.radiusOuter
    readonly property real rightRadius: Appearance.controlCenterCornerRadius
    readonly property real bodyHeight: content.implicitHeight + contentMargin * 2

    // Anchoring only `left` centers vertically for free (per wlr-layer-shell
    // rule: an axis with neither edge anchored is centered on that axis).
    anchors.left: true

    implicitWidth: panelWidth
    implicitHeight: bodyHeight + leftDrip * 2
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    // Overlay, not Top: ClickCatcher's fullscreen scrim is also on this
    // layer and would otherwise win the stacking order and swallow clicks
    // meant for this panel. Overlay always composites above Top.
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:control-center"

    // Real surface only maps while open (or animating closed, see
    // closeTimer) — otherwise this fixed-position surface would sit as an
    // invisible click-blocking dead zone while "closed".
    visible: false

    onPanelOpenChanged: {
        if (panelOpen) {
            root.visible = true
        } else {
            closeTimer.restart()
        }
    }

    Timer {
        id: closeTimer
        interval: root.morphDuration
        onTriggered: root.visible = false
    }

    Item {
        id: clipArea
        anchors.fill: parent
        clip: true

        Item {
            id: card
            width: root.panelWidth
            height: parent.height
            // Closed: slid one full width past the left edge, already
            // outside this surface's bounds — clip above is just a safety
            // net for the drip curve at the settled ends of the animation.
            x: root.panelOpen ? 0 : -root.panelWidth

            Behavior on x {
                NumberAnimation { duration: root.morphDuration; easing.type: Easing.OutExpo }
            }

            Shape {
                id: background
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer

                // Flush left edge, top and bottom both flowing into it via
                // a drip; right edge gets an ordinary rounded corner (not
                // flush against anything) in the same bezier style BarPill
                // uses for its own non-flush corners.
                ShapePath {
                    id: outline
                    fillColor: Appearance.tooltipBg
                    strokeWidth: -1

                    readonly property real d: root.leftDrip
                    readonly property real rr: root.rightRadius
                    readonly property real bgW: background.width
                    readonly property real bgH: root.bodyHeight

                    startX: 0; startY: 0

                    // Top-left drip: the flush edge's top flows into the
                    // top edge (mirror of BarPill's bottom-left drip).
                    PathCubic {
                        control1X: 0; control1Y: outline.d * 0.5
                        control2X: outline.d * 0.5; control2Y: outline.d
                        x: outline.d; y: outline.d
                    }

                    // Top edge, then an ordinary rounded corner (not
                    // flush, so no overshoot).
                    PathLine { x: outline.bgW - outline.rr; y: outline.d }

                    PathCubic {
                        control1X: outline.bgW - outline.rr * 0.5; control1Y: outline.d
                        control2X: outline.bgW; control2Y: outline.d + outline.rr * 0.5
                        x: outline.bgW; y: outline.d + outline.rr
                    }

                    PathLine { x: outline.bgW; y: outline.d + outline.bgH - outline.rr }

                    PathCubic {
                        control1X: outline.bgW; control1Y: outline.d + outline.bgH - outline.rr * 0.5
                        control2X: outline.bgW - outline.rr * 0.5; control2Y: outline.d + outline.bgH
                        x: outline.bgW - outline.rr; y: outline.d + outline.bgH
                    }

                    PathLine { x: outline.d; y: outline.d + outline.bgH }

                    // Bottom-left drip: mirror of BarPill's flush
                    // bottom-left drip, shifted down by `d` for the
                    // top-left drip's headroom.
                    PathCubic {
                        control1X: outline.d * 0.5; control1Y: outline.d + outline.bgH
                        control2X: 0; control2Y: outline.d + outline.bgH + outline.d * 0.5
                        x: 0; y: outline.d + outline.bgH + outline.d
                    }

                    PathLine { x: 0; y: 0 }
                }
            }

            ControlCenter {
                id: content
                anchors.fill: parent
                anchors.margins: root.contentMargin
                anchors.topMargin: root.contentMargin + root.leftDrip
                anchors.bottomMargin: root.contentMargin + root.leftDrip
                // Fades in only once the slide is mostly settled, so it
                // can't read as spilling past a still-mid-slide edge; fades
                // out immediately on close, ahead of the slide-out.
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

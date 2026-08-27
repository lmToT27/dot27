import Quickshell
import Quickshell.Wayland
import "../config"

// Invisible layer-shell surface that reserves screen space for Topbar.
// Topbar itself stays non-exclusive so its pop-down entrance animation
// doesn't reflow tiled windows every frame; this is what niri actually
// tiles windows against.
PanelWindow {
    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: Appearance.barHeight - 6
    WlrLayershell.layer: WlrLayer.Bottom
    color: "transparent"
    // Auto computes the reserved zone from implicitHeight + anchoring.
    exclusionMode: ExclusionMode.Auto
}

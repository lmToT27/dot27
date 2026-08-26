import Quickshell
import Quickshell.Wayland
import "../config"

// Invisible layer-shell surface that reserves screen space for Topbar.
// Topbar itself stays non-exclusive (like the old waybar config) so its
// pop-down entrance animation doesn't reflow tiled windows every frame;
// this surface is what Niri actually tiles windows against.
PanelWindow {
    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: Appearance.barHeight - 5
    WlrLayershell.layer: WlrLayer.Bottom
    color: "transparent"
    // Auto computes the reserved zone from implicitHeight + anchoring;
    // Normal requires manually setting exclusiveZone (which was never done,
    // so it stayed 0 and windows never got pushed down).
    exclusionMode: ExclusionMode.Auto
}

import "../common"
import "../../services"

HoverIcon {
    readonly property string fullTitle: Niri.activeWindowTitle

    invertOnHover: false
    text: " " + (fullTitle.length > 0
        ? (fullTitle.length > 20 ? fullTitle.slice(0, 20) + "…" : fullTitle)
        : "Desktop")
    tooltip: fullTitle.length > 0
    tooltipText: fullTitle
}

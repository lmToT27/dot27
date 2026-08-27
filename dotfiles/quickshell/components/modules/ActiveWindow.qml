import "../common"
import "../../services"

HoverIcon {
    readonly property string fullTitle: Niri.activeWindowTitle

    invertOnHover: false
    text: " " + (fullTitle.length > 0
        ? (fullTitle.length > 18 ? fullTitle.slice(0, 18) + "…" : fullTitle)
        : "Desktop")
    tooltip: fullTitle.length > 0
    tooltipText: fullTitle
}

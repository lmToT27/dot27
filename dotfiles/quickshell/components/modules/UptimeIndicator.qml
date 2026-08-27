import "../common"
import "../../services"

HoverIcon {
    id: root

    invertOnHover: false
    text: "󰅐 " + UptimeService.formatted
    tooltip: true
    tooltipText: "System uptime"
}

import "../common"
import "../../services"

HoverIcon {
    id: root

    invertOnHover: false
    tooltip: true
    text: NetworkService.kind === "ethernet" ? "󰈀"
        : NetworkService.kind === "wifi"
            ? NetworkService.wifiIcons[Math.min(NetworkService.wifiIcons.length - 1, Math.floor(NetworkService.signalStrength / 20))]
        : "󰤮"
    tooltipText: NetworkService.kind === "wifi" ? NetworkService.essid
        : NetworkService.kind === "ethernet" ? "Ethernet"
        : "Disconnected"
}

import "../common"
import "../../services"

HoverIcon {
    id: root

    invertOnHover: false
    tooltip: true
    text: !BluetoothService.powered ? "󰂲"
        : BluetoothService.connectedCount > 0 ? "󰂱" : "󰂯"
    tooltipText: BluetoothService.powered
        ? BluetoothService.controllerAlias + "\n" + BluetoothService.connectedCount + " connected"
        : "Bluetooth off"
}

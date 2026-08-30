import Quickshell
import "../common"
import "../../services"

HoverIcon {
    text: Quickshell.env("USER")
    onClicked: Niri.toggleOverview()
}

import "../common"
import "../../services"
import Quickshell.Services.UPower

// Click to cycle power-saver -> balanced -> performance. Backed by
// power-profiles-daemon — see PowerProfileService.
HoverIcon {
    id: root

    tooltip: true
    text: PowerProfileService.current === PowerProfile.PowerSaver ? "\u{f032a}"
        : PowerProfileService.current === PowerProfile.Performance ? "\u{f04c5}"
        : "\u{f05d1}"
    tooltipText: "Power: " + PowerProfile.toString(PowerProfileService.current)

    onClicked: PowerProfileService.cycle()
}

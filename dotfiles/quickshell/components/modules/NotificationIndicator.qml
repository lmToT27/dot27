import QtQuick
import "../common"
import "../../config"
import "../../services"

// Bell: reflects DND/unread state, toggles DND on click.
HoverIcon {
    id: root

    text: NotificationHistory.dnd ? "󰂛"
        : NotificationHistory.unreadCount > 0 ? "󱅫" : "󰂚"
    // The three glyphs don't share an advance width — see HoverIcon.minContentWidth.
    minContentWidth: Appearance.fontSize + 4
    tooltip: true
    tooltipText: NotificationHistory.dnd ? "Do Not Disturb" : "Notifications"

    onClicked: NotificationHistory.toggleDnd()
}

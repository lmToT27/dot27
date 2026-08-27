import QtQuick
import "../common"

HoverIcon {
    id: root

    property date now: new Date()
    property bool showFullDate: false

    text: showFullDate
        ? Qt.formatDate(now, "dddd, dd MMMM yyyy")
        : Qt.formatDateTime(now, "HH:mm")
    // Mirrors waybar's actions.on-click-right: "mode" (cycles format).
    onClicked: showFullDate = !showFullDate

    // Aligns to the next minute boundary once, then ticks every 60s —
    // no need for a per-second Timer since the display only shows HH:mm.
    Timer {
        id: tick
        repeat: false
        running: true
        interval: 60000 - (Date.now() % 60000)
        onTriggered: {
            root.now = new Date()
            interval = 60000
            repeat = true
            restart()
        }
    }

    // Right-click toggles the calendar open/closed (see HoverIcon.infoOpen)
    // instead of hover, since hover kept getting clipped by the bar.
    CalendarPopup {
        id: popup
        anchorItem: root
        panelOpen: root.infoOpen
        referenceDate: root.now
        onDismissed: root.infoOpen = false
    }
}

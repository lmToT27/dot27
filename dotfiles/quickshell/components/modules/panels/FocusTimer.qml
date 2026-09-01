import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../common"
import "../../../config"
import "../../../services"

// Row 1's left column: a duration picker plus Set/Stop controls for a
// focus session countdown. Self-contained — the countdown Timer only runs
// while a session is active, so this stays event-driven at idle.
//
// hours/minutes are aliases straight onto each tumbler's own `value`
// instead of a separate bound property, so there's no live binding for a
// later imperative write to accidentally destroy — each NumberTumbler's
// `value: N` below is just a one-time initial default, not an ongoing
// binding.
ColumnLayout {
    id: root

    readonly property alias hours: hourTumbler.value
    readonly property alias minutes: minuteTumbler.value

    property bool running: false
    property int remainingSeconds: 0
    // NixOS has no FHS /usr/share — reachable only via the current system
    // profile's stable symlink, not the versioned /nix/store path.
    property string alarmSoundPath: "/run/current-system/sw/share/sounds/freedesktop/stereo/complete.oga"

    readonly property string remainingLabel: {
        const m = Math.floor(root.remainingSeconds / 60)
        const s = root.remainingSeconds % 60
        return String(m).padStart(2, '0') + ":" + String(s).padStart(2, '0')
    }

    function start() {
        const total = hourTumbler.value * 3600 + minuteTumbler.value * 60
        if (total <= 0) return
        root.remainingSeconds = total
        root.running = true
        // The actual DND switch — same flag the bell/Notification Center read.
        NotificationHistory.dnd = true
    }

    // Shared by the Stop button and the countdown hitting 00:00, so both
    // paths turn DND back off and reset the UI the same way.
    function stop() {
        root.running = false
        root.remainingSeconds = 0
        hourTumbler.value = 0
        minuteTumbler.value = 0
        NotificationHistory.dnd = false
    }

    spacing: 6

    Timer {
        interval: 1000
        running: root.running
        repeat: true
        onTriggered: {
            root.remainingSeconds -= 1
            if (root.remainingSeconds <= 0) {
                root.stop()
                // media-role=Notification opts into WirePlumber's
                // role-based ducking, so the chime cuts through any
                // competing Music/Movie-role stream instead of getting
                // buried under it.
                Quickshell.execDetached(["pw-play", "--media-role=Notification", root.alarmSoundPath])
                Quickshell.execDetached(["notify-send", "-a", "Focus Timer", "Focus session complete"])
            }
        }
    }

    Text {
        Layout.alignment: Qt.AlignHCenter
        text: root.running ? root.remainingLabel : "Set Focus Timer"
        color: root.running ? Theme.accent : Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.45)
        font.bold: true
        font.pixelSize: 14
        font.family: Appearance.fontFamily
    }

    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: 4
        enabled: !root.running
        opacity: root.running ? 0.35 : 1

        NumberTumbler {
            id: hourTumbler
            count: 24
            value: 0
        }

        Text {
            text: ":"
            color: Theme.accent
            font.bold: true
            font.pixelSize: 18
            font.family: Appearance.fontFamily
        }

        NumberTumbler {
            id: minuteTumbler
            count: 60
            value: 30
        }
    }

    // Both buttons rely on Layout.fillWidth with no preferred-width hint,
    // so RowLayout splits the space exactly 50/50 regardless of "Set" vs
    // "Stop" text width.
    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 22
            radius: 6
            // Alpha, not Rectangle.opacity — opacity cascades to the child
            // Text and double-blends it, washing out its contrast.
            color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, root.running ? 0.4 : 1)
            scale: setMouseArea.pressed ? 0.95 : 1
            Behavior on scale { NumberAnimation { duration: 100 } }

            Text {
                id: setLabel
                anchors.centerIn: parent
                text: "Set"
                font.family: Appearance.fontFamily
                font.pixelSize: 11
                font.bold: true
                color: Theme.accentContrast
            }

            MouseArea {
                id: setMouseArea
                anchors.fill: parent
                enabled: !root.running
                onClicked: mouse => {
                    // Consumed so this tap can't also read as a
                    // click-outside that dismisses the panel.
                    mouse.accepted = true
                    root.start()
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 22
            radius: 6
            color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, root.running ? 1 : 0.4)
            scale: stopMouseArea.pressed ? 0.95 : 1
            Behavior on scale { NumberAnimation { duration: 100 } }

            Text {
                id: stopLabel
                anchors.centerIn: parent
                text: "Stop"
                font.family: Appearance.fontFamily
                font.pixelSize: 11
                font.bold: true
                color: Theme.accentContrast
            }

            MouseArea {
                id: stopMouseArea
                anchors.fill: parent
                enabled: root.running
                onClicked: mouse => {
                    mouse.accepted = true
                    root.stop()
                }
            }
        }
    }
}

pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.UPower

// Thin wrapper around Quickshell's native UPower PowerProfiles binding —
// reads/writes the profile over D-Bus, event-driven via profileChanged.
QtObject {
    id: root

    readonly property var order: [PowerProfile.PowerSaver, PowerProfile.Balanced, PowerProfile.Performance]
    readonly property int current: PowerProfiles.profile

    function cycle() {
        const idx = root.order.indexOf(PowerProfiles.profile)
        PowerProfiles.profile = root.order[(idx + 1) % root.order.length]
    }

    function setProfile(profile) {
        PowerProfiles.profile = profile
    }

    // Suppresses the notification for the initial sync on startup — that's
    // just picking up existing state, not a real change.
    property bool initialized: false

    readonly property Connections conn: Connections {
        target: PowerProfiles
        function onProfileChanged() {
            if (root.initialized) {
                Quickshell.execDetached(["notify-send", "-a", "Power Profile",
                    "Power profile changed", PowerProfile.toString(PowerProfiles.profile)])
            }
            root.initialized = true
        }
    }
}

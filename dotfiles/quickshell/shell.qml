import Quickshell
import "./components"
import "./services"

ShellRoot {
    Variants {
        model: Quickshell.screens

        ExclusionZone {
            required property var modelData
            screen: modelData
        }
    }

    Variants {
        model: Quickshell.screens

        Topbar {
            required property var modelData
            screen: modelData
        }
    }

    Variants {
        model: Quickshell.screens

        ClickCatcher {
            required property var modelData
            screen: modelData
            active: ControlCenterState.open
            onDismissRequested: ControlCenterState.hide()
        }
    }

    Variants {
        model: Quickshell.screens

        ClickCatcher {
            required property var modelData
            screen: modelData
            active: NotificationCenterState.open
            onDismissRequested: NotificationCenterState.hide()
        }
    }

    Variants {
        model: Quickshell.screens

        ControlCenterWindow {
            required property var modelData
            screen: modelData
        }
    }

    Variants {
        model: Quickshell.screens

        NotificationCenterWindow {
            required property var modelData
            screen: modelData
        }
    }

    Variants {
        model: Quickshell.screens

        NotificationToastWindow {
            required property var modelData
            screen: modelData
        }
    }
}

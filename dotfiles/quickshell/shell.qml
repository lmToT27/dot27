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

        ClickCatcher {
            required property var modelData
            screen: modelData
            active: AppLauncherState.open
            onDismissRequested: AppLauncherState.hide()
        }
    }

    Variants {
        model: Quickshell.screens

        ClickCatcher {
            required property var modelData
            screen: modelData
            active: WallpaperPickerState.open
            onDismissRequested: WallpaperPickerState.hide()
        }
    }

    Variants {
        model: Quickshell.screens

        ClickCatcher {
            required property var modelData
            screen: modelData
            active: ThemePickerState.open
            onDismissRequested: ThemePickerState.hide()
        }
    }

    Variants {
        model: Quickshell.screens

        ClickCatcher {
            required property var modelData
            screen: modelData
            active: ScreenRecorderState.open
            onDismissRequested: ScreenRecorderState.hide()
        }
    }

    Variants {
        model: Quickshell.screens

        AppLauncherWindow {
            required property var modelData
            screen: modelData
        }
    }

    Variants {
        model: Quickshell.screens

        WallpaperPickerWindow {
            required property var modelData
            screen: modelData
        }
    }

    Variants {
        model: Quickshell.screens

        ThemePickerWindow {
            required property var modelData
            screen: modelData
        }
    }

    Variants {
        model: Quickshell.screens

        ScreenRecorderWindow {
            required property var modelData
            screen: modelData
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

    Variants {
        model: Quickshell.screens

        OsdWindow {
            required property var modelData
            screen: modelData
        }
    }

    Variants {
        model: Quickshell.screens

        DropzoneWindow {
            required property var modelData
            screen: modelData
        }
    }
}

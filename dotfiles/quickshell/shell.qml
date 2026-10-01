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
        ClickCatcher {
            required property var modelData
            screen: modelData
            active: ClipboardState.open
            onDismissRequested: ClipboardState.hide()
        }
    }

    Variants {
        model: Quickshell.screens
        ClickCatcher {
            required property var modelData
            screen: modelData
            active: EmojiPickerState.open
            onDismissRequested: EmojiPickerState.hide()
        }
    }

    AppLauncherWindow {
        screen: Quickshell.cursorScreen
    }

    ClipboardWindow {
        screen: Quickshell.cursorScreen
    }

    EmojiPickerWindow {
        screen: Quickshell.cursorScreen
    }

    WallpaperPickerWindow {
        screen: Quickshell.cursorScreen
    }

    ThemePickerWindow {
        screen: Quickshell.cursorScreen
    }

    WifiListWindow {
        screen: Quickshell.cursorScreen
    }

    BluetoothListWindow {
        screen: Quickshell.cursorScreen
    }

    ScreenRecorderWindow {
        screen: Quickshell.cursorScreen
    }

    ControlCenterWindow {
        screen: Quickshell.cursorScreen
    }

    NotificationCenterWindow {
        screen: Quickshell.cursorScreen
    }

    NotificationToastWindow {
        screen: Quickshell.cursorScreen
    }

    OsdWindow {
        screen: Quickshell.cursorScreen
    }

    DropzoneWindow {
        screen: Quickshell.cursorScreen
    }
}

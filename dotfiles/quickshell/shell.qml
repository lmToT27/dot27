import Quickshell
import "./components"

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
}

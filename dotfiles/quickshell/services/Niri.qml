pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    property string activeWindowTitle: ""
    property string activeWindowAppId: ""
    property bool overviewOpen: false

    function toggleOverview() {
        Quickshell.execDetached(["niri", "msg", "action", "toggle-overview"])
    }

    // Long-running: niri streams one JSON event per line, so state stays
    // in sync without ever polling on a Timer.
    property Process eventStream: Process {
        command: ["niri", "msg", "--json", "event-stream"]
        running: true
        stdout: SplitParser {
            onRead: line => root._handleEvent(line)
        }
    }

    property Process windowQuery: Process {
        command: ["niri", "msg", "--json", "focused-window"]
        stdout: StdioCollector {
            onStreamFinished: root._setActiveWindow(text)
        }
    }

    function _handleEvent(line) {
        if (!line) return
        let event
        try {
            event = JSON.parse(line)
        } catch (e) {
            return
        }

        if (event.WindowFocusChanged || event.WindowOpenedOrChanged || event.WindowClosed) {
            root.windowQuery.running = true
        } else if (event.OverviewOpenedOrClosed) {
            root.overviewOpen = event.OverviewOpenedOrClosed.is_open
        }
    }

    function _setActiveWindow(text) {
        try {
            const win = JSON.parse(text)
            root.activeWindowTitle = win && win.title ? win.title : ""
            root.activeWindowAppId = win && win.app_id ? win.app_id : ""
        } catch (e) {
            root.activeWindowTitle = ""
            root.activeWindowAppId = ""
        }
    }

    Component.onCompleted: windowQuery.running = true
}

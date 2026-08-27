pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Real conditions via wttr.in's JSON endpoint — no API key needed,
// geolocates from the request's own IP. Only polls while `active` is set
// (see the Binding in WeatherWidget.qml).
QtObject {
    id: root

    property bool active: false

    property int temperature: 0
    property string condition: ""
    property string icon: "󰖙"

    function _iconFor(desc) {
        const d = desc.toLowerCase()
        if (d.includes("thunder")) return "󰙾"
        if (d.includes("snow")) return "󰖘"
        if (d.includes("rain") || d.includes("drizzle")) return "󰖗"
        if (d.includes("cloud") || d.includes("overcast")) return "󰖐"
        if (d.includes("fog") || d.includes("mist") || d.includes("haze")) return "󰖑"
        return "󰖙"
    }

    function _apply(json) {
        try {
            const data = JSON.parse(json)
            const cur = data.current_condition[0]
            root.temperature = parseInt(cur.temp_C)
            root.condition = cur.weatherDesc[0].value
            root.icon = root._iconFor(root.condition)
        } catch (e) {
            // Transient/malformed response — keep the last good value.
        }
    }

    readonly property Process query: Process {
        command: ["curl", "-s", "--max-time", "8", "wttr.in/?format=j1"]
        stdout: StdioCollector { onStreamFinished: root._apply(text) }
    }

    // 15 minutes — conditions don't change fast enough to justify tighter,
    // and this is a free public endpoint worth being conservative with.
    readonly property Timer pollTimer: Timer {
        interval: 900000
        repeat: true
        running: root.active
        triggeredOnStart: true
        onTriggered: query.running = true
    }
}

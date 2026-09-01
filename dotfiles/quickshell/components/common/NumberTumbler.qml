import QtQuick
import "../../config"
import "../../services"

// Vertical "combination lock" digit picker (Control Center's Focus Timer
// HH:MM). Snapping/centering come from ListView's own StrictlyEnforceRange
// highlight behavior. Infinite wrap is faked with a virtual model `laps`
// times bigger than `count`, every index reduced mod count for both the
// displayed digit and the emitted `value`; the wheel starts in the middle
// of that range so there's no reachable edge in either direction.
ListView {
    id: root

    property int count: 60
    property int value: 0
    readonly property int itemHeight: 32
    readonly property int visibleRows: 3
    readonly property int laps: 1000

    width: 48
    height: itemHeight * visibleRows
    model: count * (laps * 2 + 1)
    clip: true

    snapMode: ListView.SnapOneItem
    highlightRangeMode: ListView.StrictlyEnforceRange
    preferredHighlightBegin: itemHeight * Math.floor(visibleRows / 2)
    preferredHighlightEnd: preferredHighlightBegin + itemHeight
    highlightMoveDuration: 150

    // ListView auto-picks a currentIndex as soon as the model is attached,
    // before this component's own initial positioning runs — `ready` keeps
    // the sync handlers below inert until that's done, so the auto-pick
    // can't corrupt the real initial value.
    property bool ready: false

    Component.onCompleted: {
        currentIndex = count * laps + value
        positionViewAtIndex(currentIndex, ListView.Center)
        ready = true
    }

    onCurrentIndexChanged: if (ready) root.value = currentIndex % root.count
    // Lets an external write to `value` move the wheel — only reacts when
    // diverged from scrolling, so it can't fight the user mid-drag.
    onValueChanged: if (ready && currentIndex % count !== value) currentIndex = count * laps + value

    readonly property real centerIndex: (contentY + preferredHighlightBegin) / itemHeight

    delegate: Item {
        id: cell
        required property int index
        width: root.width
        height: root.itemHeight

        readonly property real distance: Math.abs(index - root.centerIndex)
        readonly property bool current: distance < 0.5

        Text {
            anchors.centerIn: parent
            text: String(cell.index % root.count).padStart(2, '0')
            font.family: Appearance.fontFamily
            font.pixelSize: cell.current ? 20 : 18
            font.bold: cell.current
            color: cell.current ? Theme.fg : Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.35)
            opacity: cell.current ? 1 : Math.max(0.3, 1 - cell.distance * 0.4)
        }
    }
}

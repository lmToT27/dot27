import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../config"
import "../../services"

// Real separate popup surface — see StyledTooltip.qml for why (the bar's
// own PanelWindow surface is clipped to barHeight, so a plain child Item
// can't render below it).
PopupWindow {
    id: root

    property Item anchorItem: null
    property bool panelOpen: false
    property date referenceDate: new Date()
    property int viewYear: referenceDate.getFullYear()
    property int viewMonth: referenceDate.getMonth()

    // Auto-dismisses (fires closed()) when the user clicks anywhere outside
    // the popup, instead of staying open until Clock.qml toggles it again.
    // Deliberately does NOT write root.panelOpen here: Clock.qml binds it
    // declaratively (`panelOpen: root.infoOpen`), so an imperative write
    // would permanently destroy that binding after the first dismiss.
    signal dismissed()
    grabFocus: true
    onClosed: root.dismissed()

    // Simple fade in/out — keeps the surface alive through the fade-out
    // instead of cutting it short (same reasoning as ControlCenterWindow.qml).
    onPanelOpenChanged: {
        if (panelOpen) {
            root.visible = true
        } else {
            closeTimer.restart()
        }
    }

    Timer {
        id: closeTimer
        interval: Appearance.animFast
        onTriggered: root.visible = false
    }

    readonly property var weekdays: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
    readonly property date firstOfMonth: new Date(viewYear, viewMonth, 1)
    readonly property int leadingBlanks: (firstOfMonth.getDay() + 6) % 7
    readonly property int daysInMonth: new Date(viewYear, viewMonth + 1, 0).getDate()

    readonly property int cellSize: 28
    readonly property int gridSpacing: 4
    readonly property int cardMargin: 12
    readonly property color weekdayColor: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.6)
    readonly property color dayColor: Qt.rgba(1, 1, 1, 0.82)

    function shiftMonth(delta) {
        const d = new Date(viewYear, viewMonth + delta, 1)
        viewYear = d.getFullYear()
        viewMonth = d.getMonth()
    }

    anchor.item: anchorItem
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    anchor.margins.top: 32

    implicitWidth: cellSize * 7 + gridSpacing * 6 + cardMargin * 2
    implicitHeight: content.implicitHeight + cardMargin * 2
    visible: false
    color: "transparent"

    Rectangle {
        id: card
        anchors.fill: parent
        radius: Appearance.radiusOuter
        color: Appearance.tooltipBg
        opacity: root.panelOpen ? 1 : 0

        Behavior on opacity {
            NumberAnimation { duration: Appearance.animFast; easing.type: Easing.OutCubic }
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.NoButton
            onWheel: wheel => root.shiftMonth(wheel.angleDelta.y > 0 ? -1 : 1)
        }

        ColumnLayout {
            id: content
            anchors.fill: parent
            anchors.margins: root.cardMargin
            spacing: 10

            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                color: Theme.accent
                font.bold: true
                font.pixelSize: 15
                font.letterSpacing: 0.5
                font.family: Appearance.fontFamily
                text: Qt.formatDate(new Date(root.viewYear, root.viewMonth, 1), "MMMM yyyy")
            }

            GridLayout {
                Layout.alignment: Qt.AlignHCenter
                columns: 7
                columnSpacing: root.gridSpacing
                rowSpacing: root.gridSpacing

                Repeater {
                    model: root.weekdays
                    delegate: Text {
                        required property string modelData
                        Layout.preferredWidth: root.cellSize
                        horizontalAlignment: Text.AlignHCenter
                        text: modelData
                        color: root.weekdayColor
                        font.bold: true
                        font.pixelSize: 11
                    }
                }

                Repeater {
                    model: root.leadingBlanks
                    delegate: Item { Layout.preferredWidth: root.cellSize; Layout.preferredHeight: root.cellSize }
                }

                Repeater {
                    model: root.daysInMonth
                    delegate: Rectangle {
                        id: cell
                        required property int index
                        readonly property int day: index + 1
                        readonly property bool isToday: root.viewYear === new Date().getFullYear()
                            && root.viewMonth === new Date().getMonth()
                            && day === new Date().getDate()

                        Layout.preferredWidth: root.cellSize
                        Layout.preferredHeight: root.cellSize
                        radius: width / 2
                        // Today gets a soft accent glow instead of a solid
                        // filled circle — the number itself lights up.
                        color: isToday ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.18) : "transparent"

                        Text {
                            anchors.fill: parent
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            text: cell.day
                            color: cell.isToday ? Theme.accent : root.dayColor
                            font.bold: true
                            font.pixelSize: 13
                        }
                    }
                }
            }
        }
    }
}

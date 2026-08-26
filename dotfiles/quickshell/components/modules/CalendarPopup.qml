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
    property date referenceDate: new Date()
    property int viewYear: referenceDate.getFullYear()
    property int viewMonth: referenceDate.getMonth()

    readonly property var weekdays: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
    readonly property date firstOfMonth: new Date(viewYear, viewMonth, 1)
    readonly property int leadingBlanks: (firstOfMonth.getDay() + 6) % 7
    readonly property int daysInMonth: new Date(viewYear, viewMonth + 1, 0).getDate()

    readonly property int cellSize: 28
    readonly property int gridSpacing: 4
    readonly property int cardMargin: 12
    readonly property color weekdayColor: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.6)
    readonly property color dayColor: Qt.rgba(1, 1, 1, 0.82)

    // Perceived luminance of the accent — picks a readable mark for whatever
    // accent color the active theme sets (light pastel vs. dark saturated).
    function contrastOn(c) {
        return (0.299 * c.r + 0.587 * c.g + 0.114 * c.b) > 0.6 ? "#1a1a1a" : "#ffffff"
    }

    function shiftMonth(delta) {
        const d = new Date(viewYear, viewMonth + delta, 1)
        viewYear = d.getFullYear()
        viewMonth = d.getMonth()
    }

    anchor.item: anchorItem
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    anchor.margins.top: 8

    implicitWidth: cellSize * 7 + gridSpacing * 6 + cardMargin * 2
    implicitHeight: content.implicitHeight + cardMargin * 2
    color: "transparent"

    Rectangle {
        id: card
        anchors.fill: parent
        radius: Appearance.radiusOuter
        color: Appearance.tooltipBg

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
                        color: isToday ? Theme.accent : "transparent"

                        Text {
                            anchors.fill: parent
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            text: cell.day
                            color: cell.isToday ? root.contrastOn(Theme.accent) : root.dayColor
                            font.bold: true
                            font.pixelSize: 13
                        }
                    }
                }
            }
        }
    }
}

pragma Singleton
import QtQuick

QtObject {
    readonly property string fontFamily: "JetBrainsMono Nerd Font"
    readonly property int fontSize: 14

    readonly property int barHeight: 35

    readonly property int controlCenterWidth: 380
    readonly property int controlCenterCornerRadius: 24

    readonly property int radiusOuter: 16
    readonly property int radiusInner: 10

    readonly property int paddingH: 12
    readonly property int paddingV: 4
    readonly property int moduleGap: 8

    readonly property color surface: Qt.rgba(0, 0, 0, 1)
    readonly property color tooltipBg: Qt.rgba(0, 0, 0, 1)

    readonly property color warning: "#e0af68"
    readonly property color critical: "#f7768e"
    readonly property color charging: "#9ece6a"

    readonly property int animFast: 150
    readonly property int animMedium: 300
    readonly property int popDuration: 600
}

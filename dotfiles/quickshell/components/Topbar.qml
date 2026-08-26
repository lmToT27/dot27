import QtQuick
import Quickshell
import "./modules"
import "./common"
import "../config"

PanelWindow {
    id: bar

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: Appearance.barHeight
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    Item {
        id: content
        anchors.fill: parent
        opacity: 0
        y: -parent.height

        ParallelAnimation {
            running: true
            NumberAnimation { target: content; property: "opacity"; to: 1; duration: Appearance.popDuration; easing.type: Easing.OutCubic }
            NumberAnimation { target: content; property: "y"; to: 0; duration: Appearance.popDuration; easing.type: Easing.OutCubic }
        }

        BarPill {
            anchors.left: parent.left
            anchors.top: parent.top
            cornerBottomRight: Appearance.radiusOuter
            spacing: 0

            OverviewButton {}
            ActiveWindow {}
        }

        BarPill {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            cornerBottomLeft: Appearance.radiusOuter
            cornerBottomRight: Appearance.radiusOuter

            Clock {}
            CavaVisualizer {}
            MediaWidget {}
        }

        BarPill {
            anchors.right: parent.right
            anchors.top: parent.top
            cornerBottomLeft: Appearance.radiusOuter

            NetworkIndicator {}
            BluetoothIndicator {}
            BatteryIndicator {}
            NotificationCenter {}
        }
    }
}

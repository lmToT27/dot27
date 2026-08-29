import QtQuick
import Quickshell
import "./modules"
import "./common"
import "../config"
import "../services"

// Purely visual — ExclusionZone.qml is the surface niri actually reserves
// tiling space against, so this one stays non-exclusive.
//
// A wlr-layer-shell surface accepts pointer input across its whole
// surface regardless of paint transparency, so `implicitHeight` is pinned
// to `content`'s measured height and `mask` restricts input to the three
// pills — gaps between them pass clicks through to the window below.
PanelWindow {
    id: bar

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: content.implicitHeight
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    mask: Region {
        Region { item: leftPill }
        Region { item: middlePill }
        Region { item: rightPill }
    }

    Item {
        id: content

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        implicitHeight: childrenRect.height

        opacity: 0

        y: -height

        ParallelAnimation {
            id: popIn
            NumberAnimation { target: content; property: "opacity"; to: 1; duration: Appearance.popDuration; easing.type: Easing.OutCubic }
            NumberAnimation { target: content; property: "y"; to: 0; duration: Appearance.popDuration; easing.type: Easing.OutCubic }
        }

        ParallelAnimation {
            id: popOut
            NumberAnimation { target: content; property: "opacity"; to: 0; duration: Appearance.popDuration; easing.type: Easing.OutCubic }
            NumberAnimation { target: content; property: "y"; to: -content.height; duration: Appearance.popDuration; easing.type: Easing.OutCubic }
        }

        Component.onCompleted: popIn.start()

        Connections {
            target: TopbarState
            function onOpenChanged() {
                if (TopbarState.open) popIn.start(); else popOut.start()
            }
        }

        BarPill {
            id: leftPill
            anchors.left: parent.left
            anchors.top: parent.top
            spacing: 0
            alignContentLeft: true
            flushLeft: true

            OverviewButton {}
            ActiveWindow {}
        }

        BarPill {
            id: middlePill
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top

            Clock {}
            CavaVisualizer {}
            MediaWidget {}
            ScreenRecordIndicator {}
        }

        BarPill {
            id: rightPill
            anchors.right: parent.right
            anchors.top: parent.top
            flushRight: true
            UptimeIndicator {}
            NetworkIndicator {}
            BluetoothIndicator {}
            PowerProfileIndicator {}
            BatteryIndicator {}
            NotificationIndicator {}
        }
    }
}

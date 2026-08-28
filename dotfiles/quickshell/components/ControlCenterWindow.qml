import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import "./modules"
import "../config"
import "../services"

PanelWindow {
    id: root

    readonly property int panelWidth: Appearance.controlCenterWidth
    readonly property int contentMargin: 16
    readonly property int morphDuration: 350

    readonly property bool panelOpen: ControlCenterState.open

    readonly property real leftDrip: Appearance.radiusOuter
    readonly property real rightRadius: Appearance.controlCenterCornerRadius
    readonly property real bodyHeight: content.implicitHeight + contentMargin * 2

    anchors.left: true

    implicitWidth: panelWidth
    implicitHeight: bodyHeight + leftDrip * 2
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:control-center"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    visible: false

    onPanelOpenChanged: {
        if (panelOpen) {
            root.visible = true
        } else {
            closeTimer.restart()
        }
    }

    Timer {
        id: closeTimer
        interval: root.morphDuration
        onTriggered: root.visible = false
    }

    Shortcut {
        sequence: "Escape"
        onActivated: ControlCenterState.hide()
    }

    Item {
        id: clipArea
        anchors.fill: parent
        clip: true

        Item {
            id: card
            width: root.panelWidth
            height: parent.height
            x: root.panelOpen ? 0 : -root.panelWidth

            Behavior on x {
                NumberAnimation { duration: root.morphDuration; easing.type: Easing.OutExpo }
            }

            Shape {
                id: background
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer

                ShapePath {
                    id: outline
                    fillColor: Appearance.tooltipBg
                    strokeWidth: -1

                    readonly property real d: root.leftDrip
                    readonly property real rr: root.rightRadius
                    readonly property real bgW: background.width
                    readonly property real bgH: root.bodyHeight

                    startX: 0; startY: 0

                    PathCubic {
                        control1X: 0; control1Y: outline.d * 0.5
                        control2X: outline.d * 0.5; control2Y: outline.d
                        x: outline.d; y: outline.d
                    }

                    PathLine { x: outline.bgW - outline.rr; y: outline.d }

                    PathCubic {
                        control1X: outline.bgW - outline.rr * 0.5; control1Y: outline.d
                        control2X: outline.bgW; control2Y: outline.d + outline.rr * 0.5
                        x: outline.bgW; y: outline.d + outline.rr
                    }

                    PathLine { x: outline.bgW; y: outline.d + outline.bgH - outline.rr }

                    PathCubic {
                        control1X: outline.bgW; control1Y: outline.d + outline.bgH - outline.rr * 0.5
                        control2X: outline.bgW - outline.rr * 0.5; control2Y: outline.d + outline.bgH
                        x: outline.bgW - outline.rr; y: outline.d + outline.bgH
                    }

                    PathLine { x: outline.d; y: outline.d + outline.bgH }

                    PathCubic {
                        control1X: outline.d * 0.5; control1Y: outline.d + outline.bgH
                        control2X: 0; control2Y: outline.d + outline.bgH + outline.d * 0.5
                        x: 0; y: outline.d + outline.bgH + outline.d
                    }

                    PathLine { x: 0; y: 0 }
                }
            }

            ControlCenter {
                id: content
                anchors.fill: parent
                anchors.margins: root.contentMargin
                anchors.topMargin: root.contentMargin + root.leftDrip
                anchors.bottomMargin: root.contentMargin + root.leftDrip
                opacity: root.panelOpen ? 1 : 0
                Behavior on opacity {
                    SequentialAnimation {
                        PauseAnimation { duration: root.panelOpen ? root.morphDuration / 2 : 0 }
                        NumberAnimation { duration: root.morphDuration / 2; easing.type: Easing.OutCubic }
                    }
                }
            }
        }
    }
}

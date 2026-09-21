import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../config"
import "../services"

PanelWindow {
    id: root

    readonly property int pillWidth: (dispIsMic || dispMuted) ? Math.ceil(contentRow.implicitWidth) + 36 : 220
    readonly property int pillHeight: 40
    readonly property bool isBrightness: OsdState.kind === "brightness"
    readonly property bool isMic: OsdState.kind === "mic"
    readonly property real level: isBrightness ? BrightnessService.percent : AudioService.volume
    readonly property bool muted: isMic ? AudioService.micMuted : (!isBrightness && AudioService.muted)
    readonly property real shownPct: muted ? 0 : Math.max(0, Math.min(100, level))
    readonly property real dispShownPct: dispMuted ? 0 : Math.max(0, Math.min(100, level))

    property string dispKind: ""
    property bool dispMuted: false
    readonly property bool dispIsMic: dispKind === "mic"
    readonly property bool dispIsBrightness: dispKind === "brightness"

    function syncDisplay() {
        dispKind = OsdState.kind
        dispMuted = root.muted
    }

    Component.onCompleted: syncDisplay()

    readonly property bool atMax: !isMic && level >= 100
    readonly property bool atMin: !isMic && level <= 0
    property string heldSide: ""
    property bool bumpHeld: false
    property real bumpPeak: 1.0

    function pulseBoundary() {
        const side = atMax ? "max" : (atMin ? "min" : "")
        if (side === "" || side !== heldSide) {
            heldSide = side
            if (bumpHeld) {
                bumpHeld = false
                growAnim.stop()
                shrinkBackAnim.restart()
            }
            return
        }
        bumpPeak = side === "max" ? 1.08 : 0.92
        if (!bumpHeld) {
            bumpHeld = true
            shrinkBackAnim.stop()
            growAnim.to = bumpPeak
            growAnim.restart()
        }
        releaseTimer.restart()
    }

    Connections {
        target: OsdState
        function onTriggerChanged() { root.pulseBoundary() }
    }

    Timer {
        id: releaseTimer
        interval: 180
        onTriggered: {
            root.heldSide = ""
            root.bumpHeld = false
            growAnim.stop()
            shrinkBackAnim.restart()
        }
    }

    readonly property int bumpPad: 10

    anchors { bottom: true; left: false; right: false; top: false }
    margins.bottom: 30 - bumpPad

    implicitWidth: pillWidth + bumpPad * 2
    implicitHeight: pillHeight + bumpPad * 2
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:osd"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    visible: false

    readonly property bool osdActive: OsdState.active

    onOsdActiveChanged: {
        if (root.osdActive) {
            root.visible = true
        } else {
            hideTimer.restart()
        }
    }

    Timer {
        id: hideTimer
        interval: Appearance.animFast + 50
        onTriggered: if (!root.osdActive) root.visible = false
    }

    property real swapOpacity: 1.0

    function triggerSwap() {
        if (!root.osdActive) return
        if (swapAnim.running) {
            root.syncDisplay()
            return
        }
        swapAnim.restart()
    }

    Connections {
        target: OsdState
        function onKindChanged() { root.triggerSwap() }
    }

    onMutedChanged: root.triggerSwap()

    SequentialAnimation {
        id: swapAnim
        ParallelAnimation {
            NumberAnimation { target: root; property: "swapOpacity"; to: 0; duration: 110; easing.type: Easing.InCubic }
            NumberAnimation { target: swapScale; properties: "xScale,yScale"; to: 0.7; duration: 110; easing.type: Easing.InCubic }
        }
        ScriptAction { script: root.syncDisplay() }
        ParallelAnimation {
            NumberAnimation { target: root; property: "swapOpacity"; to: 1; duration: 220; easing.type: Easing.OutCubic }
            NumberAnimation { target: swapScale; properties: "xScale,yScale"; to: 1.0; duration: 220; easing.type: Easing.OutBack }
        }
    }

    Rectangle {
        id: pill
        anchors.centerIn: parent
        width: root.pillWidth
        height: root.pillHeight
        radius: height / 2
        color: Appearance.tooltipBg
        border.width: 0
        border.color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.1)

        opacity: root.osdActive ? 1 : 0
        scale: root.osdActive ? 1 : 0.9
        Behavior on opacity { NumberAnimation { duration: Appearance.animFast; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: Appearance.animFast; easing.type: Easing.OutCubic } }

        transform: [
            Scale {
                id: bumpScale
                origin.x: pill.width / 2
                origin.y: pill.height / 2
                xScale: 1
                yScale: 1
            },
            Scale {
                id: swapScale
                origin.x: pill.width / 2
                origin.y: pill.height / 2
                xScale: 1
                yScale: 1
            }
        ]

        NumberAnimation {
            id: growAnim
            target: bumpScale
            properties: "xScale,yScale"
            duration: 90
            easing.type: Easing.OutQuad
        }

        NumberAnimation {
            id: shrinkBackAnim
            target: bumpScale
            properties: "xScale,yScale"
            to: 1.0
            duration: 180
            easing.type: Easing.OutBack
        }

        RowLayout {
            id: contentRow
            anchors.fill: parent
            anchors.leftMargin: 18
            anchors.rightMargin: 18
            spacing: root.dispIsMic ? 10 : (root.dispMuted ? 3 : 12)
            opacity: root.swapOpacity

            Text {
                // The mute glyph renders visually larger than the other
                // volume icons at the same pixelSize (fuller Nerd Font
                // glyph box) — sized down slightly to match.
                readonly property bool isMuteGlyph: !root.dispIsMic && !root.dispIsBrightness && (root.dispMuted || root.level <= 0)

                font.family: Appearance.fontFamily
                font.pixelSize: isMuteGlyph ? 16 : 18
                color: Theme.accent
                text: {
                    if (root.dispIsMic) return root.dispMuted ? "󰍭" : "󰍬"
                    if (root.dispIsBrightness) return "󰃠"
                    if (isMuteGlyph) return "󰖁"
                    if (root.level < 33) return "󰕿"
                    if (root.level < 66) return "󰖀"
                    return "󰕾"
                }
            }

            Rectangle {
                visible: !root.dispIsMic && !root.dispMuted
                Layout.fillWidth: true
                Layout.preferredHeight: 6
                radius: 3
                color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.15)

                Rectangle {
                    height: parent.height
                    width: parent.width * (root.dispShownPct / 100)
                    radius: 3
                    color: Theme.accent
                    Behavior on width { NumberAnimation { duration: Appearance.animFast; easing.type: Easing.OutCubic } }
                }
            }

            Text {
                visible: root.dispIsMic
                font.family: Appearance.fontFamily
                font.pixelSize: 13
                font.weight: Font.DemiBold
                color: Theme.accent
                text: "Microphone " + (root.dispMuted ? "Muted" : "On")
            }

            Text {
                visible: !root.dispIsMic
                Layout.preferredWidth: root.dispMuted ? 50 : 34
                horizontalAlignment: Text.AlignRight
                font.family: Appearance.fontFamily
                font.pixelSize: 12
                font.weight: Font.DemiBold
                color: Theme.accent
                text: root.dispMuted ? "Muted" : Math.round(root.dispShownPct) + "%"
            }
        }
    }
}

import QtQuick
import QtQuick.Shapes
import "../../config"

Item {
    id: pill

    default property alias content: inner.data
    property alias spacing: inner.spacing
    property bool alignContentLeft: false

    property bool flushLeft: false
    property bool flushRight: false

    readonly property real r: Appearance.radiusOuter
    readonly property real fwL: flushLeft ? 0 : r * 0.5
    readonly property real fwR: flushRight ? 0 : r * 0.5
    readonly property real crL: flushLeft ? 0 : r
    readonly property real crR: flushRight ? 0 : r

    readonly property real dripL: flushLeft ? r : 0
    readonly property real dripR: flushRight ? r : 0

    readonly property real bodyWidth: inner.implicitWidth + Appearance.paddingH * 2
    readonly property real bodyHeight: inner.implicitHeight + Appearance.paddingV * 2

    implicitWidth: bodyWidth + fwL + fwR
    implicitHeight: bodyHeight + Math.max(dripL, dripR)
    
    clip: false

    // Content (HoverIcon's own text-crop Behavior) owns the deliberate,
    // user-visible morph pace via pillResizeDuration — this Behavior only
    // exists for children that pop in/out without animating their own
    // width (e.g. NotificationIndicator glyph swap, MediaWidget appearing).
    // It must stay fast relative to that: re-triggering a long ease on a
    // target that's ALREADY mid-animation (bodyWidth tracks HoverIcon's
    // animated width every frame) compounds into a visible lag — the pill
    // looks frozen, then chases the text after the fact. animFast keeps it
    // essentially glued to whatever content is already doing.
    Behavior on implicitWidth {
        NumberAnimation { duration: Appearance.animFast; easing.type: Easing.OutCubic }
    }
    Behavior on implicitHeight {
        NumberAnimation { duration: Appearance.animFast; easing.type: Easing.OutCubic }
    }

    Shape {
        id: background
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            id: outline
            fillColor: Appearance.surface
            strokeWidth: -1

            readonly property real hL: pill.fwL * 0.5
            readonly property real hR: pill.fwR * 0.5
            
            readonly property real bgW: background.width
            readonly property real bgH: pill.bodyHeight 

            startX: 0; startY: 0
            
            PathLine { x: outline.bgW; y: 0 }

            PathCubic {
                control1X: outline.bgW - outline.hR; control1Y: 0
                control2X: outline.bgW - pill.fwR; control2Y: outline.hR
                x: outline.bgW - pill.fwR; y: pill.fwR
            }

            PathLine { 
                x: outline.bgW - pill.fwR 
                y: pill.flushRight ? outline.bgH + pill.r : outline.bgH - pill.crR 
            }

            PathCubic {
                control1X: outline.bgW - pill.fwR
                control1Y: pill.flushRight ? outline.bgH + pill.r * 0.5 : outline.bgH - pill.crR * 0.5
                control2X: pill.flushRight ? outline.bgW - pill.r * 0.5 : outline.bgW - pill.fwR - pill.crR * 0.5
                control2Y: outline.bgH
                x: pill.flushRight ? outline.bgW - pill.r : outline.bgW - pill.fwR - pill.crR
                y: outline.bgH
            }

            PathLine { 
                x: pill.flushLeft ? pill.r : pill.fwL + pill.crL
                y: outline.bgH 
            }

            PathCubic {
                control1X: pill.flushLeft ? pill.r * 0.5 : pill.fwL + pill.crL * 0.5
                control1Y: outline.bgH
                control2X: pill.flushLeft ? 0 : pill.fwL
                control2Y: pill.flushLeft ? outline.bgH + pill.r * 0.5 : outline.bgH - pill.crL * 0.5
                x: pill.flushLeft ? 0 : pill.fwL
                y: pill.flushLeft ? outline.bgH + pill.r : outline.bgH - pill.crL
            }

            PathLine { x: pill.flushLeft ? 0 : pill.fwL; y: pill.fwL }

            PathCubic {
                control1X: pill.flushLeft ? 0 : pill.fwL; control1Y: outline.hL
                control2X: outline.hL; control2Y: 0
                x: 0; y: 0
            }
        }
    }

    Row {
        id: inner
        y: Appearance.paddingV 
        anchors.left: pill.alignContentLeft ? parent.left : undefined
        anchors.leftMargin: pill.alignContentLeft ? Appearance.paddingH + pill.fwL : 0
        anchors.horizontalCenter: pill.alignContentLeft ? undefined : parent.horizontalCenter
        spacing: Appearance.moduleGap

        // Keeps a centered pill's content centered as its total width
        // changes (separate from children repositioning below). Fast, for
        // the same reason as the implicitWidth Behaviors above — this
        // chases a width that may already be mid-animation.
        Behavior on x {
            NumberAnimation { duration: Appearance.animFast; easing.type: Easing.OutCubic }
        }

        // Matches the implicitWidth Behavior above so a sibling
        // growing/shrinking slides content and resizes the pill together,
        // instead of snapping children to their new slot instantly.
        move: Transition {
            NumberAnimation { properties: "x,y"; duration: Appearance.animFast; easing.type: Easing.OutCubic }
        }

        onChildrenChanged: {
            for (const child of inner.children) {
                child.Row.verticalItemAlignment = Row.AlignVCenter
            }
        }
    }
}

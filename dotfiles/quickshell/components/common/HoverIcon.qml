import QtQuick
import "../../config"
import "../../services"

Item {
    id: root

    property string text: ""
    property int fontSize: Appearance.fontSize
    property color textColor: Theme.accent
    property bool invertOnHover: true
    property bool blinking: false
    property bool tooltip: false
    property string tooltipText: ""
    property color borderColor: "transparent"
    property int borderWidth: 0
    // Floors the label width so a glyph-swapping button (e.g. DND bell)
    // doesn't resize the bar pill on every click. 0 = no floor.
    property int minContentWidth: 0

    readonly property bool hovered: mouseArea.containsMouse
    // Right-click toggles the info tooltip instead of hover, which gets
    // clipped/overlapped by the bar itself.
    property bool infoOpen: false

    signal clicked()

    implicitWidth: Math.round(Math.max(viewport.width, minContentWidth) + Appearance.paddingH)
    implicitHeight: Math.round(Math.max(label.implicitHeight, 20))

    Rectangle {
        anchors.fill: parent
        radius: Appearance.radiusInner + 2
        color: root.invertOnHover && root.hovered ? Theme.accent : "transparent"
        border.color: root.borderColor
        border.width: root.borderWidth
        Behavior on color { ColorAnimation { duration: Appearance.animMedium } }
    }

    // Clips `label` to an animated width so text length changes reveal or
    // crop the string instead of popping — `measurer` (invisible, always
    // holding the latest text) supplies the target width immediately,
    // decoupled from whatever `label` is currently painting.
    Item {
        id: viewport
        width: measurer.implicitWidth
        height: label.implicitHeight
        // Left edge fixed, right edge grows/shrinks — except when
        // minContentWidth floors root wider than the text (e.g. the DND
        // bell glyph swap), which needs true centering instead.
        x: root.minContentWidth > width
            ? Math.round((parent.width - width) / 2)
            : Math.round(Appearance.paddingH / 2)
        y: Math.round((parent.height - height) / 2)
        clip: true

        // Every HoverIcon lives inside a BarPill, whose own resize Behavior
        // (implicitWidth/x/move in BarPill.qml) chases this width — using
        // Appearance.pillResizeDuration here instead of animFast keeps both
        // in lockstep instead of the pill lagging behind an already-settled
        // text reveal. InOutCubic (not OutCubic) because OutCubic front-loads
        // most of the width change into the first ~40% of the duration —
        // chasing that with another eased Behavior in BarPill reads as an
        // instant pop plus an imperceptible tail, not a morph.
        Behavior on width {
            NumberAnimation { duration: Appearance.pillResizeDuration; easing.type: Easing.InOutCubic }
        }

        // Guarantees `label.text` always converges to `root.text`, on a
        // fixed timer rather than "when the width animation finishes" —
        // two different-but-equal-length titles (common: ActiveWindow's
        // fixed 18-char truncation + a monospace font means most long
        // titles measure identically) never change `viewport.width` at
        // all, so a width-driven trigger would silently never fire.
        Timer {
            id: swapTimer
            interval: Appearance.pillResizeDuration
            onTriggered: label.text = measurer.text
        }

        Text {
            id: measurer
            text: root.text
            font: label.font
            visible: false

            // Grow: swap immediately so widening reveals the new text as
            // it goes. Shrink (or same-width): swap after the crop plays.
            onTextChanged: {
                if (implicitWidth > label.implicitWidth) label.text = measurer.text
                else swapTimer.restart()
            }
        }

        Text {
            id: label
            text: root.text
            font.family: Appearance.fontFamily
            font.pixelSize: root.fontSize
            font.bold: true
            color: root.invertOnHover && root.hovered ? Theme.accentContrast : root.textColor
            Behavior on color { ColorAnimation { duration: Appearance.animMedium } }

            SequentialAnimation on opacity {
                running: root.blinking
                loops: Animation.Infinite
                NumberAnimation { to: 0.5; duration: 500 }
                NumberAnimation { to: 1.0; duration: 500 }
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        anchors.margins: -4
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        pressAndHoldInterval: 400

        // Qt still emits clicked() on release after a pressAndHold fires, so
        // this flag consumes that trailing click instead of double-firing.
        property bool suppressClick: false

        onPressed: suppressClick = false
        onPressAndHold: mouse => {
            if (mouse.button !== Qt.LeftButton) return
            suppressClick = true
        }
        onClicked: mouse => {
            if (suppressClick) {
                suppressClick = false
                return
            }
            if (mouse.button === Qt.RightButton) {
                root.infoOpen = !root.infoOpen
            } else {
                root.clicked()
            }
        }
    }

    StyledTooltip {
        anchorItem: root
        panelOpen: root.tooltip && root.infoOpen && root.tooltipText.length > 0
        text: root.tooltipText
        onDismissed: root.infoOpen = false
    }
}

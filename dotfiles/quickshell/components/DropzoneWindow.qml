import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import "../config"
import "../services"

// Stateful morphing dropzone, an edge-drawer flush against the right
// screen edge:
//   ghost (no files, idle)      -> 8x200 near-invisible hit strip
//   expanded (drag hovering in) -> 280x320 panel
//   stowed (has files, idle)    -> 48x140 tab with icon/count
//   expanded (has files, hover) -> 280x320 panel again, for drag-out
PanelWindow {
    id: root

    readonly property int ghostWidth: 8
    readonly property int ghostHeight: 200
    readonly property int stowedWidth: 48
    readonly property int stowedHeight: 140
    readonly property int expandedWidth: 280
    readonly property int expandedHeight: 320

    // Set by the file-row MouseArea while a drag-out is in progress, so the
    // panel stays expanded even once the cursor leaves the pill bounds.
    property bool itemDragActive: false

    property string uiState: {
        if (dropArea.containsDrag) return "expanded"
        if (DropzoneState.files.count === 0) return "ghost"
        if (mainHoverArea.containsMouse || root.itemDragActive) return "expanded"
        return "stowed"
    }

    function targetPillSize() {
        if (uiState === "expanded") return { w: expandedWidth, h: expandedHeight }
        if (uiState === "stowed") return { w: stowedWidth, h: stowedHeight }
        return { w: ghostWidth, h: ghostHeight }
    }

    // The actual Wayland surface size — deliberately decoupled from the
    // visual pill below. Animating implicitWidth/implicitHeight directly
    // forces niri to recompute the wlr-layer-shell surface's layout every
    // frame (severe stutter), so the real surface jumps instantly instead
    // while visualPill animates its own width/height inside it.
    //
    // Ghost/stowed/expanded aren't all square any more (8x200, 48x140,
    // 280x320), so a transition can grow on one axis while shrinking on the
    // other at the same time (e.g. ghost->stowed: width 8->48 grows, height
    // 200->140 shrinks). Each axis is therefore grown instantly or
    // delay-shrunk independently — a single combined grow/shrink flag would
    // snap the shrinking axis's surface out from under the still-animating
    // pill and clip it.
    property real currentWlWidth: ghostWidth
    property real currentWlHeight: ghostHeight

    onUiStateChanged: {
        const t = targetPillSize()
        if (t.w > currentWlWidth) currentWlWidth = t.w
        if (t.h > currentWlHeight) currentWlHeight = t.h
        if (t.w < currentWlWidth || t.h < currentWlHeight) {
            shrinkTimer.restart()
        } else {
            shrinkTimer.stop()
        }
    }

    Timer {
        id: shrinkTimer
        interval: 400
        onTriggered: {
            const t = root.targetPillSize()
            root.currentWlWidth = t.w
            root.currentWlHeight = t.h
        }
    }

    implicitWidth: currentWlWidth
    implicitHeight: currentWlHeight

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    // The surface buffer is briefly larger than the visual pill while
    // shrinkTimer is pending (see above) — mask input to the pill's actual
    // rendered bounds so that oversized margin doesn't eat clicks meant for
    // whatever's behind it. Same technique as Topbar.qml/AppLauncherWindow.qml.
    mask: Region { item: visualPill }
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:dropzone"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    // Flush against the right screen edge — no right margin. Raised off the
    // very bottom corner so it reads as an edge tab, not a corner pill.
    anchors { bottom: true; right: true }
    margins.bottom: 120
    margins.right: 0

    // The Morphing Visual Pill — animates independently of the Wayland surface.
    Item {
        id: visualPill
        anchors.bottom: parent.bottom
        anchors.right: parent.right

        width: root.uiState === "expanded" ? root.expandedWidth : (root.uiState === "stowed" ? root.stowedWidth : root.ghostWidth)
        height: root.uiState === "expanded" ? root.expandedHeight : (root.uiState === "stowed" ? root.stowedHeight : root.ghostHeight)
        Behavior on width { NumberAnimation { duration: 350; easing.type: Easing.OutExpo } }
        Behavior on height { NumberAnimation { duration: 350; easing.type: Easing.OutExpo } }
        clip: true

        // Flush-edge corners use the drip technique (see BarPill.qml,
        // reused in ControlCenterWindow.qml): a hand-drawn Shape/ShapePath
        // where the flush edge overshoots the body by `drip` and curves
        // back with a tangent-matched cubic bezier, never a plain radius or
        // a same-color rectangle masking a rounded corner ("CornerPatch").
        // This is the mirror of ControlCenterWindow's flush-left panel:
        // flush drip on the right (screen edge), plain rounded corners on
        // the left (facing into the screen).
        readonly property real drip: Math.min(16, height / 2)
        readonly property real leftRadius: Math.min(Appearance.controlCenterCornerRadius, width, Math.max(0, height - drip * 2) / 2)

        Shape {
            id: background
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                id: outline
                // Never fully transparent, even in the ghost/idle state: a
                // fully transparent pixel can leave the Wayland compositor
                // without a reliable input region to hit-test drag-and-drop
                // against. Ghost is still visually invisible (alpha ~0.4%).
                fillColor: root.uiState === "ghost" ? "#01000000" : Qt.rgba(Appearance.tooltipBg.r, Appearance.tooltipBg.g, Appearance.tooltipBg.b, 0.95)
                strokeColor: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.15)
                strokeWidth: root.uiState === "ghost" ? -1 : 1

                readonly property real d: visualPill.drip
                readonly property real rr: visualPill.leftRadius
                readonly property real bgW: background.width
                readonly property real bgH: Math.max(0, background.height - d * 2)

                startX: outline.bgW; startY: 0

                // Top drip: curls from the flush right edge into the body's top-right
                PathCubic {
                    control1X: outline.bgW; control1Y: outline.d * 0.5
                    control2X: outline.bgW - outline.d * 0.5; control2Y: outline.d
                    x: outline.bgW - outline.d; y: outline.d
                }
                PathLine { x: outline.rr; y: outline.d }
                // Rounded top-left (non-flush) corner
                PathCubic {
                    control1X: outline.rr * 0.5; control1Y: outline.d
                    control2X: 0; control2Y: outline.d + outline.rr * 0.5
                    x: 0; y: outline.d + outline.rr
                }
                PathLine { x: 0; y: outline.d + outline.bgH - outline.rr }
                // Rounded bottom-left (non-flush) corner
                PathCubic {
                    control1X: 0; control1Y: outline.d + outline.bgH - outline.rr * 0.5
                    control2X: outline.rr * 0.5; control2Y: outline.d + outline.bgH
                    x: outline.rr; y: outline.d + outline.bgH
                }
                PathLine { x: outline.bgW - outline.d; y: outline.d + outline.bgH }
                // Bottom drip: curls from the body's bottom-right back out to the flush right edge
                PathCubic {
                    control1X: outline.bgW - outline.d * 0.5; control1Y: outline.d + outline.bgH
                    control2X: outline.bgW; control2Y: outline.d + outline.bgH + outline.d * 0.5
                    x: outline.bgW; y: outline.bgH + outline.d * 2
                }
                // Flush right edge, full height, straight back to start
                PathLine { x: outline.bgW; y: 0 }
            }
        }

        // Global drop target — catches files dragged in from Thunar/browser/etc.
        // Kept above mainHoverArea in stacking order so it always wins drag
        // hit-testing, even while the pill is shrunken to the ghost strip.
        DropArea {
            id: dropArea
            z: 2
            anchors.fill: parent
            keys: ["text/uri-list"]
            onDropped: (drop) => {
                if (drop.hasUrls) {
                    for (let i = 0; i < drop.urls.length; i++) {
                        DropzoneState.addFile(drop.urls[i])
                    }
                    drop.acceptProposedAction()
                }
            }
        }

        // Hover-to-expand once stowed
        MouseArea {
            id: mainHoverArea
            z: 1
            anchors.fill: parent
            hoverEnabled: true
            propagateComposedEvents: true
        }

        // ---------------------------------------------------------
        // UI: STOWED STATE (mini indicator)
        // ---------------------------------------------------------
        Item {
            anchors.fill: parent
            transformOrigin: Item.Right
            scale: root.uiState === "stowed" ? 1.0 : 0.8
            opacity: root.uiState === "stowed" ? 1.0 : 0.0
            visible: opacity > 0
            Behavior on scale { NumberAnimation { duration: 350; easing.type: Easing.OutBack } }
            Behavior on opacity { NumberAnimation { duration: 250 } }

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 8

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "󰈔"
                    font.family: Appearance.fontFamily
                    font.pixelSize: 18
                    color: Theme.accent
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: DropzoneState.files.count
                    font.family: Appearance.fontFamily
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    color: Theme.fg
                }
            }
        }

        // ---------------------------------------------------------
        // UI: EXPANDED STATE (file list)
        // ---------------------------------------------------------
        Item {
            anchors.fill: parent
            transformOrigin: Item.Right
            scale: root.uiState === "expanded" ? 1.0 : 0.9
            opacity: root.uiState === "expanded" ? 1.0 : 0.0
            visible: opacity > 0
            Behavior on scale { NumberAnimation { duration: 350; easing.type: Easing.OutExpo } }
            Behavior on opacity { NumberAnimation { duration: 200 } }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        Layout.fillWidth: true
                        text: "Dropzone"
                        font.family: Appearance.fontFamily
                        font.pixelSize: 14
                        font.weight: Font.DemiBold
                        color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.6)
                    }

                    Text {
                        text: "󰃢"
                        font.family: Appearance.fontFamily
                        font.pixelSize: 16
                        color: clearMouse.containsMouse ? Appearance.critical : Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.4)

                        MouseArea {
                            id: clearMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: DropzoneState.clear()
                        }
                    }
                }

                ListView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    model: DropzoneState.files
                    spacing: 8
                    clip: true

                    delegate: Rectangle {
                        id: fileRow
                        required property string fileUrl
                        required property string fileName
                        required property bool isFolder

                        width: ListView.view.width
                        height: 44
                        radius: Appearance.radiusInner
                        color: dragArea.containsMouse
                            ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.18)
                            : "transparent"

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 12

                            Text {
                                text: fileRow.isFolder ? "󰉋" : "󰈔"
                                font.family: Appearance.fontFamily
                                font.pixelSize: 16
                                color: Theme.accent
                            }
                            Text {
                                Layout.fillWidth: true
                                text: fileRow.fileName
                                font.family: Appearance.fontFamily
                                font.pixelSize: 13
                                color: Theme.fg
                                elide: Text.ElideMiddle
                            }
                        }

                        // Drag-out onto other windows. dragDummy (not
                        // fileRow itself) is the actual drag.target/Drag.active
                        // holder: fileRow is positioned by ListView's layout,
                        // so an anchored/layout-controlled item's x/y can't be
                        // driven by drag.target — Drag.active never fires.
                        //
                        // dragDummy must also have real visual content, not
                        // just be an invisible Item: QtWayland snapshots the
                        // dragged item to build the compositor's drag-icon
                        // surface, and a contentless item produces an empty
                        // snapshot that can abort the drag outright. It's
                        // only shown for the duration of the drag itself.
                        Rectangle {
                            id: dragDummy
                            width: 140
                            height: 44
                            radius: Appearance.radiusInner
                            color: Theme.accent
                            visible: dragArea.drag.active

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 8

                                Text {
                                    text: fileRow.isFolder ? "󰉋" : "󰈔"
                                    font.family: Appearance.fontFamily
                                    font.pixelSize: 16
                                    color: Theme.accentContrast
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: fileRow.fileName
                                    font.family: Appearance.fontFamily
                                    font.pixelSize: 13
                                    color: Theme.accentContrast
                                    elide: Text.ElideMiddle
                                }
                            }

                            Drag.active: dragArea.drag.active
                            Drag.dragType: Drag.Automatic
                            Drag.supportedActions: Qt.CopyAction | Qt.MoveAction
                            // text/uri-list requires a trailing CRLF per entry
                            Drag.mimeData: ({ "text/uri-list": fileRow.fileUrl + "\r\n" })
                        }

                        MouseArea {
                            id: dragArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.OpenHandCursor
                            drag.target: dragDummy
                            drag.axis: Drag.XAndYAxis
                            onPressed: root.itemDragActive = true
                            onReleased: {
                                root.itemDragActive = false
                                dragDummy.x = 0
                                dragDummy.y = 0
                            }
                        }
                    }
                }

                Text {
                    Layout.alignment: Qt.AlignCenter
                    text: "Drop files here"
                    font.family: Appearance.fontFamily
                    font.pixelSize: 13
                    color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.3)
                    visible: DropzoneState.files.count === 0
                }
            }
        }
    }
}

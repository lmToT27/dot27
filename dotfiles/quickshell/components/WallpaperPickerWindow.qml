import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import "../config"
import "../services"

PanelWindow {
    id: root

    readonly property int pillWidth: 900
    readonly property int pillHeight: 240
    readonly property int contentMargin: 20
    readonly property int thumbWidth: 280
    readonly property int thumbHeight: 180
    readonly property int pathItemCount: 5
    readonly property int pillRadius: 32

    readonly property bool pickerOpen: WallpaperPickerState.open

    implicitWidth: pillWidth
    implicitHeight: pillHeight
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:wallpaper-picker"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    visible: false

    onPickerOpenChanged: {
        if (root.pickerOpen) {
            root.visible = true
            Qt.callLater(() => pathView.forceActiveFocus())
            // Self-heal the thumbnail cache: gen-wallpaper-thumbs.sh only
            // ever auto-runs once at niri startup, so a wallpaper dropped in
            // mid-session has no cached thumb until this catches it up.
            // Already-fresh thumbs are skipped by the script itself, so
            // this stays cheap on every open, not just the first.
            regenThumbs.running = true
        } else {
            hideTimer.restart()
        }
    }

    Timer {
        id: hideTimer
        interval: Appearance.animFast + 50
        onTriggered: if (!root.pickerOpen) root.visible = false
    }

    Process {
        id: regenThumbs
        command: [Quickshell.env("HOME") + "/.local/bin/gen-wallpaper-thumbs.sh"]
    }

    Shortcut {
        sequence: "Escape"
        onActivated: WallpaperPickerState.hide()
    }

    // gen-wallpaper-thumbs.sh pre-caches a 280x180 JPEG per wallpaper so the
    // panel doesn't decode full 4K originals on the render path.
    function thumbSource(filePath) {
        var base = filePath.substring(filePath.lastIndexOf('/') + 1)
        var dot = base.lastIndexOf('.')
        if (dot > 0) base = base.substring(0, dot)
        return "file://" + Quickshell.env("HOME") + "/.cache/wallpaper-thumbs/" + base + ".jpg"
    }

    function executeCurrentWallpaper() {
        if (!pathView.currentItem) return
        // Bare "changewallpaper.sh" would rely on quickshell's own PATH,
        // which (inherited from the niri session) doesn't include
        // ~/.local/bin — spell it out so this doesn't silently no-op.
        Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/changewallpaper.sh", pathView.currentItem.filePath])
        WallpaperPickerState.hide()
    }

    Rectangle {
        id: background
        anchors.fill: parent
        radius: root.pillRadius
        color: Appearance.tooltipBg
        border.width: 0

        opacity: root.pickerOpen ? 1 : 0
        scale: root.pickerOpen ? 1 : 0.9
        Behavior on opacity { NumberAnimation { duration: Appearance.animFast; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: Appearance.animFast; easing.type: Easing.OutBack } }

        FolderListModel {
            id: wallpaperFolder
            folder: "file://" + Quickshell.env("HOME") + "/Pictures/Wallpapers"
            nameFilters: ["*.png", "*.jpg", "*.jpeg", "*.webp"]
            showDirs: false
        }

        Text {
            anchors.centerIn: parent
            visible: wallpaperFolder.count === 0
            text: "No images found in:\n" + wallpaperFolder.folder
            color: Theme.fg
            font.family: Appearance.fontFamily
            font.pixelSize: 16
            horizontalAlignment: Text.AlignHCenter
            opacity: 0.5
        }

        PathView {
            id: pathView
            anchors.fill: parent
            anchors.margins: root.contentMargin
            clip: true
            model: wallpaperFolder
            pathItemCount: root.pathItemCount

            preferredHighlightBegin: 0.5
            preferredHighlightEnd: 0.5
            highlightRangeMode: PathView.StrictlyEnforceRange
            highlightMoveDuration: 300

            path: Path {
                startX: -pathView.width * 0.25
                startY: pathView.height / 2
                PathAttribute { name: "itemOpacity"; value: 0.3 }
                PathAttribute { name: "itemScale"; value: 0.8 }
                PathAttribute { name: "itemZ"; value: 0 }

                PathLine { x: pathView.width / 2; y: pathView.height / 2 }
                PathAttribute { name: "itemOpacity"; value: 1.0 }
                PathAttribute { name: "itemScale"; value: 1.0 }
                PathAttribute { name: "itemZ"; value: 100 }

                PathLine { x: pathView.width * 1.25; y: pathView.height / 2 }
                PathAttribute { name: "itemOpacity"; value: 0.3 }
                PathAttribute { name: "itemScale"; value: 0.8 }
                PathAttribute { name: "itemZ"; value: 0 }
            }

            focus: true
            Keys.onLeftPressed: pathView.decrementCurrentIndex()
            Keys.onRightPressed: pathView.incrementCurrentIndex()
            Keys.onReturnPressed: root.executeCurrentWallpaper()
            Keys.onEnterPressed: root.executeCurrentWallpaper()

            delegate: Item {
                id: thumb
                required property string filePath
                required property url fileUrl
                required property int index

                width: root.thumbWidth
                height: root.thumbHeight

                opacity: thumb.PathView.itemOpacity === undefined ? 1.0 : thumb.PathView.itemOpacity
                scale: thumb.PathView.itemScale === undefined ? 1.0 : thumb.PathView.itemScale
                z: thumb.PathView.itemZ === undefined ? 0 : thumb.PathView.itemZ

                ClippingRectangle {
                    id: clip
                    anchors.fill: parent
                    radius: Appearance.radiusOuter
                    color: Qt.rgba(0, 0, 0, 0.5)

                    Image {
                        id: thumbImage
                        anchors.fill: parent
                        source: root.thumbSource(thumb.filePath)
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        sourceSize.width: root.thumbWidth
                        sourceSize.height: root.thumbHeight

                        // Cache miss (e.g. a wallpaper added after the last
                        // gen-wallpaper-thumbs.sh run, which only fires once at
                        // niri startup) — fall back to decoding the original
                        // straight from disk instead of showing nothing.
                        // sourceSize still caps the decode, so this stays cheap.
                        onStatusChanged: if (status === Image.Error && source !== thumb.fileUrl) source = thumb.fileUrl
                    }

                    MouseArea {
                        id: thumbMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        Rectangle {
                            anchors.fill: parent
                            color: "white"
                            opacity: thumbMouseArea.containsMouse ? 0.15 : 0
                            Behavior on opacity { NumberAnimation { duration: 150 } }
                        }

                        onClicked: {
                            if (thumb.PathView.isCurrentItem) {
                                root.executeCurrentWallpaper()
                            } else {
                                pathView.currentIndex = thumb.index
                            }
                        }
                    }
                }

                // Selection ring drawn as a plain Rectangle border, not
                // routed through ClippingRectangle's ShaderEffectSource —
                // that renders content+border into a fixed-resolution
                // texture, which visibly breaks up ("vỡ") once PathView's
                // continuous scale (0.8→1.0) is applied on top. A native
                // Rectangle border is vector geometry, redrawn crisply at
                // every scale, and cheaper besides.
                Rectangle {
                    anchors.fill: parent
                    radius: Appearance.radiusOuter
                    color: "transparent"
                    border.width: thumb.PathView.isCurrentItem ? 4 : 0
                    border.color: Theme.accent
                }
            }
        }
    }
}

import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
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

    visible: root.pickerOpen

    onPickerOpenChanged: {
        if (root.pickerOpen) {
            Qt.callLater(() => pathView.forceActiveFocus())
        }
    }

    Shortcut {
        sequence: "Escape"
        onActivated: WallpaperPickerState.hide()
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

            delegate: ClippingRectangle {
                id: thumb
                required property string filePath
                required property url fileUrl
                required property int index

                width: root.thumbWidth
                height: root.thumbHeight
                radius: Appearance.radiusOuter
                color: Qt.rgba(0, 0, 0, 0.5)

                opacity: thumb.PathView.itemOpacity === undefined ? 1.0 : thumb.PathView.itemOpacity
                scale: thumb.PathView.itemScale === undefined ? 1.0 : thumb.PathView.itemScale
                z: thumb.PathView.itemZ === undefined ? 0 : thumb.PathView.itemZ

                border.width: thumb.PathView.isCurrentItem ? 4 : 0
                border.color: Theme.accent

                Image {
                    anchors.fill: parent
                    source: thumb.fileUrl
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    sourceSize.width: root.thumbWidth
                    sourceSize.height: root.thumbHeight
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
        }
    }
}

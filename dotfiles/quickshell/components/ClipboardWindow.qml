import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../config"
import "../services"

// Replaces cliphist-rofi.sh — same bottom-flush drip-drawer shape and
// search/keyboard-nav pattern as AppLauncherWindow.qml, adapted for a list
// that's raw `cliphist list` output instead of desktop entries.
PanelWindow {
    id: root

    readonly property int panelWidth: 700
    readonly property int maxVisibleItems: 7
    readonly property int itemHeight: 64
    readonly property int thumbSize: 48
    readonly property int searchBoxHeight: 40
    readonly property int contentMargin: 16
    readonly property real cornerRadius: Appearance.controlCenterCornerRadius
    readonly property real bottomDrip: Appearance.radiusOuter
    readonly property int morphDuration: 350

    readonly property bool clipboardOpen: ClipboardState.open
    readonly property string cacheDir: Quickshell.env("HOME") + "/.cache/cliphist/thumbnails/"
    readonly property string textIcon: "file://" + root.cacheDir + "text_icon_" + Theme.accentHex.replace("#", "") + ".png"

    property var entries: []
    property var results: []
    property int currentIndex: 0

    function refreshList() {
        listProc.running = true
        thumbsProc.running = true
    }

    function refreshResults(query) {
        const q = query.trim().toLowerCase()
        root.results = q.length === 0 ? root.entries : root.entries.filter(item => item.text.toLowerCase().includes(q))
        root.currentIndex = 0
    }

    function copyCurrent() {
        if (root.currentIndex < 0 || root.currentIndex >= root.results.length) return
        const item = root.results[root.currentIndex]
        Quickshell.execDetached(["sh", "-c", 'cliphist decode <<< "$1" | wl-copy', "--", item.raw])
        ClipboardState.hide()
    }

    function deleteCurrent() {
        if (root.currentIndex < 0 || root.currentIndex >= root.results.length) return
        const item = root.results[root.currentIndex]
        deleteProc.command = ["sh", "-c", 'cliphist delete <<< "$1"', "--", item.raw]
        deleteProc.running = true
    }

    function moveSelection(delta) {
        if (root.results.length === 0) return
        root.currentIndex = (root.currentIndex + delta + root.results.length) % root.results.length
        resultsList.positionViewAtIndex(root.currentIndex, ListView.Contain)
    }

    Process {
        id: listProc
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n").filter(l => l.length > 0)
                root.entries = lines.map(line => {
                    const tabIdx = line.indexOf("\t")
                    const id = line.substring(0, tabIdx)
                    const content = line.substring(tabIdx + 1)
                    const isImage = content.includes("[[ binary data")
                    let display
                    if (isImage) {
                        const info = content.replace(/.*\[\[ binary data /, "").replace(/ \]\]$/, "")
                        display = "Image (" + info + ")"
                    } else {
                        display = content.length > 100 ? content.substring(0, 100) : content
                    }
                    return {
                        id: id,
                        raw: line,
                        isImage: isImage,
                        text: display,
                        thumb: "file://" + root.cacheDir + id + ".png"
                    }
                })
                root.refreshResults(searchInput.text)
            }
        }
    }

    // Generates/prunes thumbnails — see cliphist-thumbs.sh. Self-skips on a
    // cache hit, so re-running on every open (mirrors gen-wallpaper-thumbs.sh
    // in WallpaperPickerWindow.qml) stays cheap.
    Process {
        id: thumbsProc
        command: [Quickshell.env("HOME") + "/.local/bin/cliphist-thumbs.sh"]
    }

    // Command is set per-call in deleteCurrent() — the raw cliphist line is
    // passed as $1 (not interpolated into the script string) so arbitrary
    // clipboard content can't inject into the shell command.
    Process {
        id: deleteProc
        onExited: {
            Quickshell.execDetached(["notify-send", "Clipboard", "Item deleted from history", "-u", "low", "-t", "2000"])
            root.refreshList()
        }
    }

    anchors { bottom: true; top: false; left: false; right: false }
    margins { bottom: 0 }

    implicitWidth: panelWidth + bottomDrip * 2
    implicitHeight: maxBodyHeight
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    mask: Region { item: card }
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:clipboard"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    visible: false

    readonly property real maxListHeight: root.maxVisibleItems * root.itemHeight
    readonly property real maxBodyHeight: root.searchBoxHeight + maxListHeight + contentMargin * 3

    readonly property real targetListHeight: Math.min(root.results.length, root.maxVisibleItems) * root.itemHeight
    readonly property real targetBodyHeight: root.searchBoxHeight + (root.results.length > 0 ? targetListHeight + contentMargin : 0) + contentMargin * 2

    property real listHeight: targetListHeight
    property real bodyHeight: targetBodyHeight

    Behavior on listHeight {
        NumberAnimation { duration: 250; easing.type: Easing.OutExpo }
    }

    Behavior on bodyHeight {
        NumberAnimation { duration: 250; easing.type: Easing.OutExpo }
    }

    onClipboardOpenChanged: {
        if (root.clipboardOpen) {
            root.visible = true
            root.refreshList()
            Qt.callLater(() => searchInput.forceActiveFocus())
        } else {
            closeTimer.restart()
        }
    }

    Timer {
        id: closeTimer
        interval: root.morphDuration
        onTriggered: {
            if (root.clipboardOpen) return
            root.visible = false
            searchInput.text = ""
            root.entries = []
            root.refreshResults("")
        }
    }

    Shortcut {
        sequence: "Escape"
        onActivated: ClipboardState.hide()
    }

    Item {
        id: clipArea
        anchors.fill: parent
        clip: true

        Item {
            id: card
            width: root.width
            height: root.bodyHeight
            y: parent.height - height

            transform: Translate {
                y: root.clipboardOpen ? 0 : root.maxBodyHeight
                Behavior on y {
                    NumberAnimation { duration: root.morphDuration; easing.type: Easing.OutExpo }
                }
            }

            Shape {
                id: background
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer

                ShapePath {
                    id: outline
                    fillColor: Appearance.tooltipBg
                    strokeWidth: -1

                    readonly property real d: root.bottomDrip
                    readonly property real r: root.cornerRadius
                    readonly property real totalW: background.width
                    readonly property real bgH: background.height

                    startX: 0; startY: outline.bgH

                    PathCubic {
                        control1X: outline.d * 0.5; control1Y: outline.bgH
                        control2X: outline.d; control2Y: outline.bgH - outline.d * 0.5
                        x: outline.d; y: outline.bgH - outline.d
                    }

                    PathLine { x: outline.d; y: outline.r }

                    PathCubic {
                        control1X: outline.d; control1Y: outline.r * 0.5
                        control2X: outline.d + outline.r * 0.5; control2Y: 0
                        x: outline.d + outline.r; y: 0
                    }

                    PathLine { x: outline.totalW - outline.d - outline.r; y: 0 }

                    PathCubic {
                        control1X: outline.totalW - outline.d - outline.r * 0.5; control1Y: 0
                        control2X: outline.totalW - outline.d; control2Y: outline.r * 0.5
                        x: outline.totalW - outline.d; y: outline.r
                    }

                    PathLine { x: outline.totalW - outline.d; y: outline.bgH - outline.d }

                    PathCubic {
                        control1X: outline.totalW - outline.d; control1Y: outline.bgH - outline.d * 0.5
                        control2X: outline.totalW - outline.d * 0.5; control2Y: outline.bgH
                        x: outline.totalW; y: outline.bgH
                    }

                    PathLine { x: 0; y: outline.bgH }
                }
            }

            Item {
                anchors.fill: parent
                anchors.topMargin: root.contentMargin
                anchors.bottomMargin: root.contentMargin
                anchors.leftMargin: root.contentMargin + root.bottomDrip
                anchors.rightMargin: root.contentMargin + root.bottomDrip

                ListView {
                    id: resultsList
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: searchBox.top
                    anchors.bottomMargin: root.results.length > 0 ? root.contentMargin : 0
                    height: root.listHeight
                    visible: root.results.length > 0
                    clip: true
                    model: root.results
                    currentIndex: root.currentIndex
                    boundsBehavior: Flickable.StopAtBounds
                    verticalLayoutDirection: ListView.BottomToTop

                    delegate: Item {
                        id: resultItem
                        required property var modelData
                        required property int index
                        width: resultsList.width
                        height: root.itemHeight

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 2
                            radius: Appearance.radiusInner
                            color: resultItem.index === root.currentIndex
                                ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.18)
                                : "transparent"
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 12

                            Item {
                                Layout.preferredWidth: root.thumbSize
                                Layout.preferredHeight: root.thumbSize
                                Layout.alignment: Qt.AlignVCenter

                                Rectangle {
                                    anchors.fill: parent
                                    visible: resultItem.modelData.isImage
                                    radius: Appearance.radiusInner
                                    color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.06)
                                }

                                Image {
                                    anchors.fill: parent
                                    anchors.margins: resultItem.modelData.isImage ? 0 : root.thumbSize * 0.1
                                    asynchronous: true
                                    sourceSize.width: root.thumbSize
                                    sourceSize.height: root.thumbSize
                                    fillMode: Image.PreserveAspectFit
                                    source: resultItem.modelData.isImage ? resultItem.modelData.thumb : root.textIcon
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: resultItem.modelData.text
                                font.family: Appearance.fontFamily
                                font.pixelSize: 15
                                color: Theme.fg
                                elide: Text.ElideRight
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: root.currentIndex = resultItem.index
                            onClicked: root.copyCurrent()
                        }
                    }
                }

                Item {
                    id: searchBox
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: root.searchBoxHeight

                    Rectangle {
                        anchors.fill: parent
                        color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.06)
                        radius: Appearance.radiusInner
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 12

                        Text {
                            Layout.preferredWidth: 24
                            Layout.preferredHeight: 24
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            text: "󰅍"
                            font.family: Appearance.fontFamily
                            font.pixelSize: 18
                            color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.35)
                        }

                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            Text {
                                anchors.fill: parent
                                verticalAlignment: Text.AlignVCenter
                                text: "Search clipboard history…"
                                visible: searchInput.text.length === 0
                                font.family: Appearance.fontFamily
                                font.pixelSize: 16
                                color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.25)
                            }

                            TextInput {
                                id: searchInput
                                anchors.fill: parent
                                verticalAlignment: Text.AlignVCenter
                                font.family: Appearance.fontFamily
                                font.pixelSize: 16
                                color: Theme.fg
                                clip: true

                                onTextChanged: root.refreshResults(text)

                                Keys.onPressed: event => {
                                    if (event.key === Qt.Key_Down) {
                                        root.moveSelection(-1)
                                        event.accepted = true
                                    } else if (event.key === Qt.Key_Up) {
                                        root.moveSelection(1)
                                        event.accepted = true
                                    } else if (event.modifiers & Qt.AltModifier && event.key === Qt.Key_Delete) {
                                        root.deleteCurrent()
                                        event.accepted = true
                                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                        root.copyCurrent()
                                        event.accepted = true
                                    } else if (event.key === Qt.Key_Escape) {
                                        ClipboardState.hide()
                                        event.accepted = true
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

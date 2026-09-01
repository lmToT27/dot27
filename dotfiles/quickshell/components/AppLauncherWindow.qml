import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import "../config"
import "../services"

PanelWindow {
    id: root

    readonly property int panelWidth: 700
    readonly property int maxVisibleItems: 7
    readonly property int itemHeight: 48
    readonly property int searchBoxHeight: 40
    readonly property int contentMargin: 16
    readonly property real cornerRadius: Appearance.controlCenterCornerRadius
    readonly property real bottomDrip: Appearance.radiusOuter

    readonly property bool launcherOpen: AppLauncherState.open

    readonly property var systemCommands: [
        { name: "Choose Wallpaper", subtitle: "System Command", icon: "󰸉",
          exec: ["quickshell", "ipc", "call", "wallpaperpicker", "toggle"] },
        { name: "Change Theme", subtitle: "System Command", icon: "󰏘",
          exec: ["quickshell", "ipc", "call", "themepicker", "toggle"] },
        { name: "Toggle Light/Dark Mode", subtitle: "System Command", icon: "\u{f050e}",
          exec: [Quickshell.env("HOME") + "/.local/bin/toggle-theme-mode.sh"] },
        { name: "Toggle Control Center", subtitle: "System Command", icon: "󰒓",
          exec: ["quickshell", "ipc", "call", "controlcenter", "toggle"] },
        { name: "Toggle Notification Center", subtitle: "System Command", icon: "󰂚",
          exec: ["quickshell", "ipc", "call", "notificationcenter", "toggle"] },
        { name: "Screen Recorder", subtitle: "System Command", icon: "󰑋",
          exec: ["quickshell", "ipc", "call", "screenrecorder", "toggle"] },
        { name: "Toggle Noise Suppression", subtitle: "System Command", icon: "󰍬",
          exec: [Quickshell.env("HOME") + "/.local/bin/noisetorch-toggle.sh"] },
        { name: "Screenshot Region", subtitle: "System Command", icon: "󰹑",
          exec: ["sh", "-c", "niri msg action screenshot && notify-send 'Clipboard' 'Saved screenshot in clipboard!'"] },
        { name: "Lock", subtitle: "System Command", icon: "\u{f033e}", exec: ["hyprlock"] },
        { name: "Sleep", subtitle: "System Command", icon: "\u{f04b2}", exec: ["systemctl", "suspend"] },
        { name: "Hibernate", subtitle: "System Command", icon: "\u{f0717}", exec: ["systemctl", "hibernate"] },
        { name: "Log Out", subtitle: "System Command", icon: "\u{f0343}", exec: ["niri", "msg", "action", "quit"] },
        { name: "Reboot", subtitle: "System Command", icon: "\u{f0709}", exec: ["systemctl", "reboot"] },
        { name: "Power Off", subtitle: "System Command", icon: "\u{f0425}", exec: ["systemctl", "poweroff"] }
    ]

    property var results: []
    property int currentIndex: 0

    function refreshResults(query) {
        const q = query.trim().toLowerCase()

        const commands = root.systemCommands.map(c => ({
            kind: "command", name: c.name, subtitle: c.subtitle, icon: c.icon, exec: c.exec
        }))

        const apps = DesktopEntries.applications.values
            .filter(e => !e.noDisplay && e.name.length > 0)
            .map(e => ({
                kind: "app", name: e.name,
                subtitle: e.genericName.length > 0 ? e.genericName : (e.comment.length > 0 ? e.comment : "Application"),
                icon: e.icon, entry: e
            }))

        const combined = commands.concat(apps)
        root.results = q.length === 0 ? combined : combined.filter(item => item.name.toLowerCase().includes(q))
        root.currentIndex = 0
    }

    function executeCurrent() {
        if (root.currentIndex < 0 || root.currentIndex >= root.results.length) return
        const item = root.results[root.currentIndex]
        if (item.kind === "app") item.entry.execute()
        else Quickshell.execDetached(item.exec)
        AppLauncherState.hide()
    }

    function moveSelection(delta) {
        if (root.results.length === 0) return
        root.currentIndex = (root.currentIndex + delta + root.results.length) % root.results.length
        resultsList.positionViewAtIndex(root.currentIndex, ListView.Contain)
    }

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

    anchors {
        bottom: true
        top: false
        left: false
        right: false
    }

    margins {
        bottom: 0
    }

    implicitWidth: panelWidth + bottomDrip * 2
    implicitHeight: maxBodyHeight
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    mask: Region { item: card }
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:app-launcher"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    visible: false

    onLauncherOpenChanged: {
        if (root.launcherOpen) {
            root.visible = true
            searchInput.text = ""
            root.refreshResults("")
            Qt.callLater(() => searchInput.forceActiveFocus())
        } else {
            closeTimer.restart()
        }
    }

    Timer {
        id: closeTimer
        interval: 350
        onTriggered: if (!root.launcherOpen) root.visible = false
    }

    Shortcut {
        sequence: "Escape"
        onActivated: AppLauncherState.hide()
    }

    Item {
        id: clipArea
        anchors.fill: parent
        clip: true

        Item {
            id: card
            width: root.width
            height: root.bodyHeight
            anchors.bottom: parent.bottom
            anchors.bottomMargin: root.launcherOpen ? 0 : -root.maxBodyHeight

            Behavior on anchors.bottomMargin {
                NumberAnimation { duration: 350; easing.type: Easing.OutExpo }
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

            ColumnLayout {
                anchors.fill: parent
                anchors.topMargin: root.contentMargin
                anchors.bottomMargin: root.contentMargin
                anchors.leftMargin: root.contentMargin + root.bottomDrip
                anchors.rightMargin: root.contentMargin + root.bottomDrip
                spacing: root.contentMargin

                ListView {
                    id: resultsList
                    Layout.fillWidth: true
                    Layout.preferredHeight: root.listHeight
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
                                Layout.preferredWidth: 24
                                Layout.preferredHeight: 24
                                Layout.alignment: Qt.AlignVCenter

                                IconImage {
                                    id: appIcon
                                    anchors.fill: parent
                                    visible: resultItem.modelData.kind === "app" && status === Image.Ready
                                    source: resultItem.modelData.kind === "app"
                                        ? Quickshell.iconPath(resultItem.modelData.icon, true) : ""
                                }

                                Text {
                                    anchors.centerIn: parent
                                    // Fallback glyph for apps with no resolvable icon.
                                    visible: resultItem.modelData.kind === "command"
                                        || (resultItem.modelData.kind === "app" && appIcon.status !== Image.Ready)
                                    text: resultItem.modelData.kind === "command" ? resultItem.modelData.icon : ""
                                    font.family: Appearance.fontFamily
                                    font.pixelSize: 16
                                    color: Theme.accent
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                spacing: 1

                                Text {
                                    Layout.fillWidth: true
                                    text: resultItem.modelData.name
                                    font.family: Appearance.fontFamily
                                    font.bold: true
                                    font.pixelSize: 14
                                    color: Theme.fg
                                    elide: Text.ElideRight
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: resultItem.modelData.subtitle
                                    font.family: Appearance.fontFamily
                                    font.pixelSize: 10
                                    color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.5)
                                    elide: Text.ElideRight
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: root.currentIndex = resultItem.index
                            onClicked: root.executeCurrent()
                        }
                    }
                }

                Item {
                    id: searchBox
                    Layout.fillWidth: true
                    Layout.preferredHeight: root.searchBoxHeight

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
                            text: "󰍉"
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
                                text: "Search apps & commands…"
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
                                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                        root.executeCurrent()
                                        event.accepted = true
                                    } else if (event.key === Qt.Key_Escape) {
                                        AppLauncherState.hide()
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

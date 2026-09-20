import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
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
    readonly property int morphDuration: 350

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

    readonly property string ollamaModel: "llama3.2"
    property string aiQuery: ""
    property bool aiLoading: false
    property string aiAnswer: ""
    property string aiAnsweredQuery: ""

    function tryEvalMath(expr) {
        if (!/[0-9]/.test(expr)) return null
        if (!/^[0-9+\-*/%.() \t^]+$/.test(expr)) return null
        if (!/[+\-*/^%]/.test(expr)) return null
        try {
            const n = Function('"use strict"; return (' + expr.replace(/\^/g, "**") + ")")()
            if (typeof n !== "number" || !isFinite(n)) return null
            return String(Math.round(n * 1e10) / 1e10)
        } catch (e) {
            return null
        }
    }

    function aiResultItem() {
        if (root.aiLoading) {
            return { kind: "ai", name: "Thinking…", subtitle: "Asking " + root.ollamaModel + " via Ollama", icon: "\u{f06a9}" }
        }
        if (root.aiAnsweredQuery === root.aiQuery && root.aiAnswer.length > 0) {
            return { kind: "ai", name: root.aiAnswer, subtitle: "Enter to copy answer · Esc to close", icon: "\u{f06a9}", isAnswer: true }
        }
        return { kind: "ai", name: "Ask AI: \"" + root.aiQuery + "\"", subtitle: "Enter to send to Ollama", icon: "\u{f06a9}" }
    }

    function refreshResults(query) {
        const q = query.trim()

        if (q.startsWith("?")) {
            root.aiQuery = q.slice(1).trim()
            root.results = root.aiQuery.length === 0 ? [] : [root.aiResultItem()]
            root.currentIndex = 0
            return
        }

        const mathResult = root.tryEvalMath(q)
        if (mathResult !== null) {
            root.results = [{ kind: "math", name: "= " + mathResult, subtitle: "Math result — Enter to copy", icon: "\u{f00ec}" }]
            root.currentIndex = 0
            return
        }

        const ql = q.toLowerCase()
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
        root.results = ql.length === 0 ? combined : combined.filter(item => item.name.toLowerCase().includes(ql))
        root.currentIndex = 0
    }

    Process {
        id: ollamaProcess
        stdout: StdioCollector {
            onStreamFinished: {
                root.aiLoading = false
                try {
                    const data = JSON.parse(text)
                    root.aiAnswer = data.error ? ("Ollama: " + data.error) : ((data.response || "").trim() || "(empty response)")
                } catch (e) {
                    root.aiAnswer = "Ollama error — is `ollama serve` running?"
                }
                root.aiAnsweredQuery = root.aiQuery
                root.refreshResults(searchInput.text)
            }
        }
    }

    function executeCurrent() {
        if (root.currentIndex < 0 || root.currentIndex >= root.results.length) return
        const item = root.results[root.currentIndex]

        if (item.kind === "app") {
            item.entry.execute()
        } else if (item.kind === "command") {
            Quickshell.execDetached(item.exec)
        } else if (item.kind === "math") {
            Quickshell.execDetached(["wl-copy", item.name.slice(2)])
        } else if (item.kind === "ai") {
            if (root.aiLoading) return
            if (root.aiAnsweredQuery === root.aiQuery && root.aiAnswer.length > 0) {
                Quickshell.execDetached(["wl-copy", root.aiAnswer])
            } else if (root.aiQuery.length > 0) {
                root.aiLoading = true
                ollamaProcess.command = ["curl", "-s", "--max-time", "60", "http://localhost:11434/api/generate",
                    "-d", JSON.stringify({ model: root.ollamaModel, prompt: root.aiQuery, stream: false })]
                ollamaProcess.running = true
                root.refreshResults(searchInput.text)
            }
            return
        }
        AppLauncherState.hide()
    }

    function moveSelection(delta) {
        if (root.results.length === 0) return
        root.currentIndex = (root.currentIndex + delta + root.results.length) % root.results.length
        resultsList.positionViewAtIndex(root.currentIndex, ListView.Contain)
    }

    readonly property real maxListHeight: root.maxVisibleItems * root.itemHeight
    readonly property real maxBodyHeight: root.searchBoxHeight + maxListHeight + contentMargin * 3

    readonly property real aiAnswerMaxHeight: root.itemHeight * 5
    readonly property bool aiAnswerShown: root.results.length === 1 && root.results[0].kind === "ai" && root.results[0].isAnswer === true

    readonly property real targetListHeight: root.aiAnswerShown
        ? (resultsList.currentItem ? resultsList.currentItem.height : root.itemHeight)
        : Math.min(root.results.length, root.maxVisibleItems) * root.itemHeight
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

    Component.onCompleted: root.refreshResults("")

    onLauncherOpenChanged: {
        if (root.launcherOpen) {
            root.visible = true
            Qt.callLater(() => searchInput.forceActiveFocus())
        } else {
            closeTimer.restart()
        }
    }

    Timer {
        id: closeTimer
        interval: root.morphDuration
        onTriggered: {
            if (root.launcherOpen) return
            root.visible = false
            searchInput.text = ""
            root.aiAnswer = ""
            root.aiAnsweredQuery = ""
            root.aiLoading = false
            root.refreshResults("")
        }
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
            // Always bottom-pinned, tracking height instantly — height's
            // own Behavior (below) already animates the grow/shrink while
            // typing. A Behavior on this y would re-chase that constantly
            // shifting target on every search keystroke, producing a
            // bounce/jump instead of a smooth resize.
            y: parent.height - height

            // Open/close slide lives entirely in this transform instead,
            // decoupled from height so searching never touches it.
            transform: Translate {
                y: root.launcherOpen ? 0 : root.maxBodyHeight
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

                // searchBox is anchored to the bottom with a fixed height —
                // it never reads an animated value, so it can't drift no
                // matter how listHeight/bodyHeight animate while typing.
                // resultsList sits above it and is the only thing that grows.
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
                        readonly property bool isAiAnswer: modelData.kind === "ai" && modelData.isAnswer === true
                        readonly property real answerOverhead: 16 + subtitleText.implicitHeight + 4
                        width: resultsList.width
                        height: resultItem.isAiAnswer
                            ? Math.min(Math.max(root.itemHeight, answerText.implicitHeight + resultItem.answerOverhead), root.aiAnswerMaxHeight)
                            : root.itemHeight

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
                            anchors.topMargin: resultItem.isAiAnswer ? 8 : 0
                            anchors.bottomMargin: resultItem.isAiAnswer ? 8 : 0
                            spacing: 12

                            Item {
                                Layout.preferredWidth: 24
                                Layout.preferredHeight: 24
                                Layout.alignment: resultItem.isAiAnswer ? Qt.AlignTop : Qt.AlignVCenter

                                IconImage {
                                    id: appIcon
                                    anchors.fill: parent
                                    visible: resultItem.modelData.kind === "app" && status === Image.Ready
                                    source: resultItem.modelData.kind === "app"
                                        ? Quickshell.iconPath(resultItem.modelData.icon, true) : ""
                                }

                                Text {
                                    anchors.centerIn: parent
                                    visible: resultItem.modelData.kind !== "app" || appIcon.status !== Image.Ready
                                    text: resultItem.modelData.kind !== "app" ? resultItem.modelData.icon : ""
                                    font.family: Appearance.fontFamily
                                    font.pixelSize: 16
                                    color: Theme.accent
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.fillHeight: resultItem.isAiAnswer
                                Layout.alignment: resultItem.isAiAnswer ? Qt.AlignTop : Qt.AlignVCenter
                                spacing: resultItem.isAiAnswer ? 4 : 1

                                Text {
                                    Layout.fillWidth: true
                                    visible: !resultItem.isAiAnswer
                                    text: resultItem.modelData.name
                                    font.family: Appearance.fontFamily
                                    font.bold: true
                                    font.pixelSize: 14
                                    color: Theme.fg
                                    elide: Text.ElideRight
                                }

                                Text {
                                    id: subtitleText
                                    Layout.fillWidth: true
                                    text: resultItem.modelData.subtitle
                                    font.family: Appearance.fontFamily
                                    font.pixelSize: 10
                                    color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.5)
                                    elide: Text.ElideRight
                                }

                                Flickable {
                                    visible: resultItem.isAiAnswer
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    clip: true
                                    contentWidth: width
                                    contentHeight: answerText.implicitHeight
                                    boundsBehavior: Flickable.StopAtBounds

                                    Text {
                                        id: answerText
                                        width: parent.width
                                        text: resultItem.modelData.name
                                        wrapMode: Text.WordWrap
                                        font.family: Appearance.fontFamily
                                        font.pixelSize: 13
                                        color: Theme.fg
                                    }
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: !resultItem.isAiAnswer
                            onEntered: root.currentIndex = resultItem.index
                            onClicked: root.executeCurrent()
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
                                text: "Search, type math, or ? to ask AI…"
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

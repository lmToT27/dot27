import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import QtWebEngine
import Qt.labs.platform as Platform
import Qt.labs.settings

Window {
    id: root

    title: "Quick Note"
    width: 560
    height: 640
    visible: true

    property color bgColor: "#000000"
    property color fgColor: "#ffffff"
    property color accentColor: "#7aa2f7"
    property color criticalColor: "#f7768e"
    property color warningColor: "#e0af68"
    property color chargingColor: "#9ece6a"
    readonly property var colorSwatches: [fgColor, accentColor, criticalColor, warningColor, chargingColor]

    property color textColor: fgColor
    property int textFontSize: 16
    property string noteText: ""
    property bool previewMode: false

    color: bgColor

    readonly property string homeDir: Platform.StandardPaths.writableLocation(Platform.StandardPaths.HomeLocation).toString()
    readonly property string katexDir: Qt.resolvedUrl("katex").toString()

    // Reads quickshell's colors.css via a hidden WebEngineView's fetch(),
    // not XMLHttpRequest — QML's own XHR can't read local files on this Qt
    // build (async never reaches DONE, sync throws on send()). Result comes
    // back via document.title, parsed by onTitleChanged below.
    function loadTheme() {
        const path = root.homeDir + "/.local/state/my_theme/colors.css"
        const html = "<script>fetch('" + path + "').then(r=>r.text()).then(t=>{document.title=t})" +
            ".catch(e=>{document.title=''})</" + "script>"
        themeReader.loadHtml(html, "file:///")
    }

    function applyThemeCss(css) {
        if (!css || css.length === 0) return
        const re = /@define-color\s+(\w+)\s+(#[0-9a-fA-F]{6,8})/g
        let match
        const found = {}
        while ((match = re.exec(css)) !== null) found[match[1]] = match[2]
        if (found.bg) root.bgColor = found.bg
        if (found.fg) root.fgColor = found.fg
        if (found.accent) root.accentColor = found.accent
    }

    WebEngineView {
        id: themeReader
        width: 10
        height: 10
        visible: false
        onTitleChanged: root.applyThemeCss(themeReader.title)
    }

    function togglePreview() {
        root.previewMode = !root.previewMode
        // Deferred a tick — see the warm-up note in Component.onCompleted.
        if (root.previewMode) Qt.callLater(() => webView.loadHtml(root.buildHtml(), "file:///"))
        else Qt.callLater(() => textEditor.forceActiveFocus())
    }

    function escapeHtml(s) {
        return s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
    }

    function inlineMd(s) {
        s = s.replace(/\*\*(.+?)\*\*/g, "<b>$1</b>")
        s = s.replace(/\*(.+?)\*/g, "<i>$1</i>")
        s = s.replace(/`([^`]+?)`/g, "<code>$1</code>")
        return s
    }

    function mdToHtml(raw) {
        const lines = root.escapeHtml(raw).split("\n")
        return lines.map(line => {
            const h = line.match(/^(#{1,6})\s+(.*)$/)
            if (h) {
                const level = h[1].length
                return "<h" + level + ">" + root.inlineMd(h[2]) + "</h" + level + ">"
            }
            const li = line.match(/^[-*]\s+(.*)$/)
            if (li) return "&bull;&nbsp;" + root.inlineMd(li[1]) + "<br>"
            return root.inlineMd(line) + "<br>"
        }).join("\n")
    }

    function buildHtml() {
        return "<!DOCTYPE html><html><head><meta charset=\"utf-8\">" +
            "<link rel=\"stylesheet\" href=\"" + root.katexDir + "/katex.min.css\">" +
            "<style>" +
            "body{background:" + root.bgColor + ";color:" + root.textColor + ";" +
            "font-family:'JetBrainsMono Nerd Font',monospace;font-size:" + root.textFontSize + "px;padding:4px;margin:0;}" +
            // Explicit header margins so they don't collapse with body's.
            "h1,h2,h3,h4,h5,h6{margin-top:4px;margin-bottom:4px;}" +
            "h1,h2,h3,h4,h5,h6{color:" + root.accentColor + ";}" +
            "code{font-family:'JetBrainsMono Nerd Font',monospace;color:" + root.accentColor + ";" +
            "background:rgba(127,127,127,0.15);padding:1px 4px;border-radius:4px;}" +
            "</style></head><body>" +
            root.mdToHtml(root.noteText) +
            "<script src=\"" + root.katexDir + "/katex.min.js\"></script>" +
            "<script src=\"" + root.katexDir + "/contrib/auto-render.min.js\"></script>" +
            "<script>renderMathInElement(document.body,{delimiters:[" +
            "{left:\"$$\",right:\"$$\",display:true}," +
            "{left:\"$\",right:\"$\",display:false}" +
            "]});</script></body></html>"
    }

    Settings {
        category: "quicknote"
        property alias noteText: root.noteText
        property alias textColor: root.textColor
        property alias textFontSize: root.textFontSize
    }

    // No FileView here (standalone process) — poll instead, same fallback
    // BatteryIndicator.qml uses for sysfs.
    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: root.loadTheme()
    }

    Component.onCompleted: {
        root.loadTheme()
        Qt.callLater(() => textEditor.forceActiveFocus())
        // Pre-warms webView's Chromium renderer so the first real Preview
        // switch doesn't pay that cold-start cost (was briefly showing
        // through to whatever's behind the window on the right/bottom edge).
        webView.loadHtml("<html><body></body></html>", "file:///")
    }

    Shortcut {
        sequence: "Ctrl+E"
        onActivated: root.togglePreview()
    }

    component ToolButton: Rectangle {
        id: btn
        property string label: ""
        property bool active: false
        property color fg: root.fgColor
        signal clicked()

        implicitWidth: Math.max(28, lbl.implicitWidth + 16)
        implicitHeight: 28
        radius: 8
        color: btn.active ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.18) : "transparent"
        border.width: btn.active ? 2 : 0
        border.color: root.accentColor

        Text {
            id: lbl
            anchors.centerIn: parent
            text: btn.label
            color: btn.active ? root.accentColor : btn.fg
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 14
            font.bold: true
        }

        MouseArea {
            anchors.fill: parent
            onClicked: btn.clicked()
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            spacing: 6

            Repeater {
                model: root.colorSwatches

                Rectangle {
                    required property color modelData
                    Layout.preferredWidth: 22
                    Layout.preferredHeight: 22
                    Layout.alignment: Qt.AlignVCenter
                    radius: 11
                    color: modelData
                    border.width: root.textColor === modelData ? 2 : 0
                    border.color: root.fgColor

                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.textColor = parent.modelData
                    }
                }
            }

            ToolButton {
                label: "−"
                onClicked: root.textFontSize = Math.max(10, root.textFontSize - 2)
            }
            Text {
                text: root.textFontSize
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 13
                color: root.fgColor
                Layout.preferredWidth: 20
                horizontalAlignment: Text.AlignHCenter
            }
            ToolButton {
                label: "+"
                onClicked: root.textFontSize = Math.min(48, root.textFontSize + 2)
            }

            Item { Layout.fillWidth: true }

            ToolButton {
                label: root.previewMode ? "\u{f0209}" : "\u{f0208}"
                active: root.previewMode
                onClicked: root.togglePreview()
            }
            ToolButton {
                label: "\u{f054c}"
                onClicked: textEditor.undo()
            }
            ToolButton {
                label: "\u{f044e}"
                onClicked: textEditor.redo()
            }
            ToolButton {
                label: "\u{f01b4}"
                fg: root.criticalColor
                onClicked: textEditor.remove(0, textEditor.text.length)
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Flickable {
                id: textFlick
                anchors.fill: parent
                visible: !root.previewMode
                clip: true
                contentWidth: width
                contentHeight: Math.max(height, textEditor.paintedHeight + 24)

                TextEdit {
                    id: textEditor
                    width: textFlick.width
                    text: root.noteText
                    onTextChanged: root.noteText = text
                    color: root.textColor
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: root.textFontSize
                    wrapMode: TextEdit.Wrap
                    selectByMouse: true
                }
            }

            // Backstop: WebEngineView's surface can lag a resize by a
            // frame, briefly showing through to whatever's behind it.
            Rectangle {
                anchors.fill: parent
                visible: root.previewMode
                color: root.bgColor
            }

            WebEngineView {
                id: webView
                anchors.fill: parent
                visible: root.previewMode
                backgroundColor: root.bgColor
            }
        }
    }
}

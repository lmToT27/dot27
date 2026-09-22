import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../config"
import "../services"

PanelWindow {
    id: root

    readonly property int pillWidth: 380
    readonly property int contentMargin: 16
    readonly property int pillRadius: 24
    readonly property int rowHeight: 42
    readonly property int sectionHeaderHeight: 22
    readonly property int maxVisibleRows: 7

    readonly property bool listOpen: WifiListState.open

    property var networks: []
    property var savedNames: ({})
    property int currentIndex: 0
    property bool scanning: false
    property bool passwordMode: false
    property string pendingSsid: ""
    property string connectingSsid: ""
    property string errorText: ""

    readonly property var connectedNets: root.networks.filter(n => n.inUse)
    readonly property var savedNets: root.networks.filter(n => !n.inUse && root.savedNames[n.ssid])
    readonly property var otherNets: root.networks.filter(n => !n.inUse && !root.savedNames[n.ssid])
    readonly property var orderedNets: root.connectedNets.concat(root.savedNets, root.otherNets)

    readonly property int sectionCount: (root.connectedNets.length > 0 ? 1 : 0)
        + (root.savedNets.length > 0 ? 1 : 0)
        + (root.otherNets.length > 0 ? 1 : 0)
    readonly property int rowCount: Math.min(root.orderedNets.length, root.maxVisibleRows)
    readonly property int listHeight: root.orderedNets.length === 0
        ? root.rowHeight
        : root.sectionCount * root.sectionHeaderHeight + root.rowCount * root.rowHeight
    readonly property int errorRowHeight: root.errorText.length > 0 ? 24 : 0
    readonly property int passwordSectionHeight: 78
    readonly property int pillHeight: root.contentMargin * 2 + 26 + 10
        + (root.passwordMode
            ? root.passwordSectionHeight
            : (root.errorRowHeight > 0 ? root.errorRowHeight + 10 : 0) + root.listHeight)

    implicitWidth: pillWidth
    implicitHeight: pillHeight
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:wifi-list"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    visible: false

    onListOpenChanged: {
        if (root.listOpen) {
            root.visible = true
            root.passwordMode = false
            root.errorText = ""
            root.currentIndex = 0
            root.refresh(false)
            Qt.callLater(() => keyGrabber.forceActiveFocus())
        } else {
            hideTimer.restart()
        }
    }

    Timer {
        id: hideTimer
        interval: Appearance.animFast + 50
        onTriggered: if (!root.listOpen) root.visible = false
    }

    Shortcut {
        sequence: "Escape"
        onActivated: {
            if (root.passwordMode) {
                root.passwordMode = false
                Qt.callLater(() => keyGrabber.forceActiveFocus())
            } else {
                WifiListState.hide()
            }
        }
    }

    function refresh(rescan) {
        root.scanning = true
        savedNamesQuery.running = true
        scanQuery.command = rescan
            ? ["nmcli", "-t", "-f", "IN-USE,SSID,SIGNAL,SECURITY", "device", "wifi", "list", "--rescan", "yes"]
            : ["nmcli", "-t", "-f", "IN-USE,SSID,SIGNAL,SECURITY", "device", "wifi", "list"]
        scanQuery.running = true
    }

    Process {
        id: savedNamesQuery
        command: ["nmcli", "-t", "-f", "NAME", "connection", "show"]
        stdout: StdioCollector {
            onStreamFinished: {
                const names = {}
                text.split("\n").filter(l => l.length > 0).forEach(n => names[n] = true)
                root.savedNames = names
            }
        }
    }

    Process {
        id: scanQuery
        stdout: StdioCollector {
            onStreamFinished: {
                root.scanning = false
                const seen = {}
                const list = []
                text.split("\n").forEach(line => {
                    if (line.length === 0) return
                    const parts = line.split(":")
                    const inUse = parts[0] === "*"
                    const ssid = parts[1]
                    const signal = parseInt(parts[2]) || 0
                    const security = parts[3] || ""
                    if (!ssid || ssid.length === 0) return
                    if (seen[ssid] && !inUse) return
                    seen[ssid] = true
                    list.push({ ssid, signal, secured: security.length > 0, inUse })
                })
                list.sort((a, b) => b.signal - a.signal)
                root.networks = list
            }
        }
    }

    function iconFor(signal) {
        if (signal >= 80) return "󰤨"
        if (signal >= 55) return "󰤥"
        if (signal >= 30) return "󰤢"
        return "󰤟"
    }

    function activate(net) {
        if (!net || root.connectingSsid.length > 0) return
        root.errorText = ""
        if (net.inUse) {
            root.connectingSsid = net.ssid
            connectProc.command = ["nmcli", "connection", "down", "id", net.ssid]
            connectProc.running = true
            connectTimeout.restart()
            return
        }
        if (net.secured && !root.savedNames[net.ssid]) {
            root.pendingSsid = net.ssid
            root.passwordMode = true
            Qt.callLater(() => passwordInput.forceActiveFocus())
            return
        }
        root.connectingSsid = net.ssid
        connectProc.command = ["nmcli", "device", "wifi", "connect", net.ssid]
        connectProc.running = true
        connectTimeout.restart()
    }

    function forget(ssid) {
        forgetProc.command = ["nmcli", "connection", "delete", "id", ssid]
        forgetProc.running = true
    }

    Process {
        id: forgetProc
        stdout: StdioCollector { onStreamFinished: root.refresh(false) }
    }

    function submitPassword(pw) {
        root.connectingSsid = root.pendingSsid
        connectProc.command = ["nmcli", "device", "wifi", "connect", root.pendingSsid, "password", pw]
        connectProc.running = true
        connectTimeout.restart()
        root.passwordMode = false
    }

    Process {
        id: connectProc
        stdout: StdioCollector {
            onStreamFinished: {
                connectTimeout.stop()
                root.connectingSsid = ""
                if (text.toLowerCase().includes("error")) root.errorText = text.trim()
                root.refresh(false)
            }
        }
    }

    Timer {
        id: connectTimeout
        interval: 15000
        onTriggered: {
            connectProc.running = false
            root.connectingSsid = ""
            root.errorText = "Timed out"
            root.refresh(false)
        }
    }

    function moveSelection(delta) {
        if (root.orderedNets.length === 0) return
        root.currentIndex = (root.currentIndex + delta + root.orderedNets.length) % root.orderedNets.length
    }

    Rectangle {
        id: pill
        anchors.fill: parent
        radius: root.pillRadius
        color: Appearance.tooltipBg
        border.width: 0

        opacity: root.listOpen ? 1 : 0
        scale: root.listOpen ? 1 : 0.9
        Behavior on opacity { NumberAnimation { duration: Appearance.animFast; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: Appearance.animFast; easing.type: Easing.OutBack } }

        Item {
            id: keyGrabber
            anchors.fill: parent
            focus: true

            Keys.onUpPressed: root.moveSelection(-1)
            Keys.onDownPressed: root.moveSelection(1)
            Keys.onReturnPressed: root.activate(root.orderedNets[root.currentIndex])
            Keys.onEnterPressed: root.activate(root.orderedNets[root.currentIndex])

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: root.contentMargin
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        Layout.fillWidth: true
                        text: "Wi-Fi Networks"
                        font.family: Appearance.fontFamily
                        font.bold: true
                        font.pixelSize: 15
                        color: Theme.fg
                    }
                    Text {
                        text: root.scanning ? "Scanning…" : "Rescan"
                        font.family: Appearance.fontFamily
                        font.pixelSize: 12
                        color: Theme.accent
                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -6
                            enabled: !root.scanning
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.refresh(true)
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    visible: root.errorText.length > 0
                    text: root.errorText
                    wrapMode: Text.WordWrap
                    font.family: Appearance.fontFamily
                    font.pixelSize: 11
                    color: Qt.rgba(1, 0.4, 0.4, 1)
                }

                Flickable {
                    id: flick
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: !root.passwordMode
                    clip: true
                    contentWidth: width
                    contentHeight: sectionsColumn.implicitHeight
                    boundsBehavior: Flickable.StopAtBounds

                    ColumnLayout {
                        id: sectionsColumn
                        width: flick.width
                        spacing: 0

                        Text {
                            Layout.fillWidth: true
                            visible: root.orderedNets.length === 0
                            Layout.preferredHeight: root.rowHeight
                            verticalAlignment: Text.AlignVCenter
                            text: root.scanning ? "Scanning…" : "No networks found"
                            font.family: Appearance.fontFamily
                            font.pixelSize: 12
                            color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.5)
                        }

                        WifiSection {
                            label: "CONNECTED"
                            nets: root.connectedNets
                            indexOffset: 0
                        }
                        WifiSection {
                            label: "SAVED"
                            nets: root.savedNets
                            indexOffset: root.connectedNets.length
                            showForget: true
                        }
                        WifiSection {
                            label: "AVAILABLE"
                            nets: root.otherNets
                            indexOffset: root.connectedNets.length + root.savedNets.length
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: root.passwordMode
                    spacing: 8

                    Text {
                        Layout.fillWidth: true
                        text: "Password for \"" + root.pendingSsid + "\""
                        font.family: Appearance.fontFamily
                        font.pixelSize: 13
                        color: Theme.fg
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 40
                        radius: Appearance.radiusInner
                        color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.06)

                        TextInput {
                            id: passwordInput
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            verticalAlignment: Text.AlignVCenter
                            font.family: Appearance.fontFamily
                            font.pixelSize: 14
                            color: Theme.fg
                            echoMode: TextInput.Password
                            clip: true

                            Keys.onReturnPressed: root.submitPassword(text)
                            Keys.onEnterPressed: root.submitPassword(text)
                        }
                    }

                    Item { Layout.fillHeight: true }
                }
            }
        }
    }

    component WifiSection: ColumnLayout {
        id: section
        required property string label
        required property var nets
        required property int indexOffset
        property bool showForget: false
        visible: nets.length > 0
        spacing: 0
        Layout.fillWidth: true

        Text {
            Layout.fillWidth: true
            Layout.preferredHeight: root.sectionHeaderHeight
            verticalAlignment: Text.AlignVCenter
            text: section.label
            font.family: Appearance.fontFamily
            font.pixelSize: 10
            font.bold: true
            color: Theme.accent
        }

        Repeater {
            model: section.nets
            delegate: Item {
                id: row
                required property var modelData
                required property int index
                readonly property int globalIndex: section.indexOffset + index
                readonly property bool isCurrent: globalIndex === root.currentIndex
                readonly property bool isBusy: root.connectingSsid === modelData.ssid

                Layout.fillWidth: true
                Layout.preferredHeight: root.rowHeight

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 2
                    radius: Appearance.radiusInner
                    color: row.isCurrent
                        ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.18)
                        : "transparent"
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: root.currentIndex = row.globalIndex
                    onClicked: root.activate(row.modelData)
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 10

                    Text {
                        Layout.preferredWidth: 22
                        horizontalAlignment: Text.AlignHCenter
                        text: root.iconFor(row.modelData.signal)
                        font.family: Appearance.fontFamily
                        font.pixelSize: 15
                        color: row.modelData.inUse ? Theme.accent : Theme.fg
                    }

                    Text {
                        Layout.fillWidth: true
                        text: row.modelData.ssid
                        elide: Text.ElideRight
                        font.family: Appearance.fontFamily
                        font.bold: row.modelData.inUse
                        font.pixelSize: 13
                        color: Theme.fg
                    }

                    Text {
                        visible: row.isBusy
                        text: row.modelData.inUse ? "Disconnecting…" : "Connecting…"
                        font.family: Appearance.fontFamily
                        font.pixelSize: 11
                        color: Theme.accent
                    }

                    Text {
                        visible: !row.isBusy && row.modelData.secured
                        text: "\u{f033e}"
                        font.family: Appearance.fontFamily
                        font.pixelSize: 12
                        color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.5)
                    }

                    Text {
                        visible: !row.isBusy && section.showForget
                        text: "\u{f01b4}"
                        font.family: Appearance.fontFamily
                        font.pixelSize: 12
                        color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.4)

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -6
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.forget(row.modelData.ssid)
                        }
                    }
                }
            }
        }
    }
}

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

    readonly property bool listOpen: BluetoothListState.open

    property var devices: []
    property int currentIndex: 0
    property bool scanning: false
    property string busyMac: ""

    readonly property var connectedDevs: root.devices.filter(d => d.connected)
    readonly property var pairedDevs: root.devices.filter(d => d.paired && !d.connected)
    readonly property var newDevs: root.devices.filter(d => !d.paired)
    readonly property var orderedDevs: root.connectedDevs.concat(root.pairedDevs, root.newDevs)

    readonly property int sectionCount: (root.connectedDevs.length > 0 ? 1 : 0)
        + (root.pairedDevs.length > 0 ? 1 : 0)
        + (root.newDevs.length > 0 ? 1 : 0)
    readonly property int rowCount: Math.min(root.orderedDevs.length, root.maxVisibleRows)
    readonly property int listHeight: root.orderedDevs.length === 0
        ? root.rowHeight
        : root.sectionCount * root.sectionHeaderHeight + root.rowCount * root.rowHeight
    readonly property int pillHeight: root.contentMargin * 2 + 26 + 10 + root.listHeight

    implicitWidth: pillWidth
    implicitHeight: pillHeight
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:bluetooth-list"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    visible: false

    onListOpenChanged: {
        if (root.listOpen) {
            root.visible = true
            root.currentIndex = 0
            root.refresh()
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
        onActivated: BluetoothListState.hide()
    }

    function refresh() {
        refreshProc.running = true
    }

    Process {
        id: refreshProc
        command: ["sh", "-c", "bluetoothctl devices Paired; echo ---CONNECTED---; bluetoothctl devices Connected"]
        stdout: StdioCollector {
            onStreamFinished: {
                const [pairedBlock, connectedBlock] = text.split("---CONNECTED---")
                const connectedMacs = {}
                connectedBlock.split("\n").forEach(l => {
                    const m = l.match(/^Device (\S+)/)
                    if (m) connectedMacs[m[1]] = true
                })
                const list = []
                pairedBlock.split("\n").forEach(l => {
                    const m = l.match(/^Device (\S+) (.+)$/)
                    if (!m) return
                    list.push({ mac: m[1], name: m[2], paired: true, connected: !!connectedMacs[m[1]] })
                })
                root.devices = list
            }
        }
    }

    function scanForDevices() {
        root.scanning = true
        scanProc.running = true
    }

    Process {
        id: scanProc
        command: ["sh", "-c", "bluetoothctl --timeout 6 scan on; bluetoothctl devices"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.scanning = false
                const known = {}
                root.devices.forEach(d => known[d.mac] = true)
                const fresh = [...root.devices]
                text.split("\n").forEach(l => {
                    const m = l.match(/^Device (\S+) (.+)$/)
                    if (!m || known[m[1]]) return
                    fresh.push({ mac: m[1], name: m[2], paired: false, connected: false })
                })
                root.devices = fresh
            }
        }
    }

    property string busyAction: ""

    function activate(dev) {
        if (!dev || root.busyMac.length > 0) return
        root.busyMac = dev.mac
        if (dev.connected) {
            root.busyAction = "Disconnecting…"
            actionProc.command = ["bluetoothctl", "disconnect", dev.mac]
        } else if (dev.paired) {
            root.busyAction = "Connecting…"
            actionProc.command = ["bluetoothctl", "connect", dev.mac]
        } else {
            root.busyAction = "Pairing…"
            actionProc.command = ["sh", "-c", "bluetoothctl pair " + dev.mac + " && bluetoothctl connect " + dev.mac]
        }
        actionProc.running = true
        actionTimeout.restart()
    }

    function forget(mac) {
        forgetProc.command = ["bluetoothctl", "remove", mac]
        forgetProc.running = true
    }

    Process {
        id: forgetProc
        stdout: StdioCollector { onStreamFinished: root.refresh() }
    }

    Process {
        id: actionProc
        stdout: StdioCollector {
            onStreamFinished: {
                actionTimeout.stop()
                root.busyMac = ""
                root.refresh()
            }
        }
    }

    Timer {
        id: actionTimeout
        interval: 12000
        onTriggered: {
            actionProc.running = false
            root.busyMac = ""
            root.refresh()
        }
    }

    function moveSelection(delta) {
        if (root.orderedDevs.length === 0) return
        root.currentIndex = (root.currentIndex + delta + root.orderedDevs.length) % root.orderedDevs.length
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
            Keys.onReturnPressed: root.activate(root.orderedDevs[root.currentIndex])
            Keys.onEnterPressed: root.activate(root.orderedDevs[root.currentIndex])

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: root.contentMargin
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        Layout.fillWidth: true
                        text: "Bluetooth Devices"
                        font.family: Appearance.fontFamily
                        font.bold: true
                        font.pixelSize: 15
                        color: Theme.fg
                    }

                    Text {
                        text: root.scanning ? "Scanning…" : "Scan"
                        font.family: Appearance.fontFamily
                        font.pixelSize: 12
                        color: Theme.accent

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -6
                            enabled: !root.scanning
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.scanForDevices()
                        }
                    }
                }

                Flickable {
                    id: flick
                    Layout.fillWidth: true
                    Layout.fillHeight: true
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
                            visible: root.orderedDevs.length === 0
                            Layout.preferredHeight: root.rowHeight
                            verticalAlignment: Text.AlignVCenter
                            text: root.scanning ? "Scanning…" : "No devices found"
                            font.family: Appearance.fontFamily
                            font.pixelSize: 12
                            color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.5)
                        }

                        BluetoothSection {
                            label: "CONNECTED"
                            devs: root.connectedDevs
                            indexOffset: 0
                            showForget: true
                        }
                        BluetoothSection {
                            label: "PAIRED"
                            devs: root.pairedDevs
                            indexOffset: root.connectedDevs.length
                            showForget: true
                        }
                        BluetoothSection {
                            label: "DISCOVERED"
                            devs: root.newDevs
                            indexOffset: root.connectedDevs.length + root.pairedDevs.length
                        }
                    }
                }
            }
        }
    }

    component BluetoothSection: ColumnLayout {
        id: section
        required property string label
        required property var devs
        required property int indexOffset
        property bool showForget: false
        visible: devs.length > 0
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
            model: section.devs
            delegate: Item {
                id: row
                required property var modelData
                required property int index
                readonly property int globalIndex: section.indexOffset + index
                readonly property bool isCurrent: globalIndex === root.currentIndex
                readonly property bool isBusy: root.busyMac === modelData.mac

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
                        text: "\u{f00af}"
                        font.family: Appearance.fontFamily
                        font.pixelSize: 15
                        color: row.modelData.connected ? Theme.accent : Theme.fg
                    }

                    Text {
                        Layout.fillWidth: true
                        text: row.modelData.name
                        elide: Text.ElideRight
                        font.family: Appearance.fontFamily
                        font.bold: row.modelData.connected
                        font.pixelSize: 13
                        color: Theme.fg
                    }

                    Text {
                        visible: row.isBusy
                        text: root.busyAction
                        font.family: Appearance.fontFamily
                        font.pixelSize: 11
                        color: Theme.accent
                    }

                    Text {
                        visible: !row.isBusy
                        text: row.modelData.connected ? "Disconnect"
                            : row.modelData.paired ? "Connect"
                            : "Pair"
                        font.family: Appearance.fontFamily
                        font.pixelSize: 11
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
                            onClicked: root.forget(row.modelData.mac)
                        }
                    }
                }
            }
        }
    }
}

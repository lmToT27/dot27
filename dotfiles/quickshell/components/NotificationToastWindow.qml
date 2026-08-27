import QtQuick
import Quickshell
import Quickshell.Wayland
import "./common"
import "../config"
import "../services"

// Standalone OSD popup, floats at the top-right corner, independent of
// NotificationCenterWindow (history sidebar) and NotificationIndicator
// (topbar bell) — this is what actually alerts you when a notification
// arrives.
//
// Reuses NotificationCard as-is for the card UI so the toast and the
// history list never visually drift apart — this file only owns the
// surface, queue, backdrop, and per-toast enter/auto-dismiss/exit choreography.
PanelWindow {
    id: root

    readonly property int toastWidth: Appearance.controlCenterWidth
    readonly property int autoDismissMs: 4000

    anchors { top: true; right: true }
    // Below the topbar, not just below the screen edge.
    margins.top: Appearance.barHeight + 12
    margins.right: 20

    implicitWidth: toastWidth
    implicitHeight: column.implicitHeight
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:notification-toast"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    // Unmapped whenever the queue is empty — same reasoning as
    // ControlCenterWindow/NotificationCenterWindow.
    visible: toastModel.count > 0

    ListModel { id: toastModel }

    // Removes by id, not index: several toasts can be in flight with
    // independent timers, and an earlier removal would shift later
    // indices. String() on both sides: entry.id is a DBus number,
    // toastId is a `required property string` — comparing directly with
    // === always fails across those two types.
    function removeToast(toastId) {
        for (let i = 0; i < toastModel.count; i++) {
            if (String(toastModel.get(i).toastId) === String(toastId)) {
                toastModel.remove(i)
                return
            }
        }
    }

    // Dismissing a toast never touches NotificationHistory — it only
    // clears the transient popup; the record stays for the sidebar.
    Connections {
        target: NotificationHistory
        function onNotified(entry) {
            if (NotificationHistory.dnd) return
            toastModel.insert(0, {
                toastId: entry.id,
                appName: entry.appName,
                summary: entry.summary,
                body: entry.body
            })
        }
    }

    Column {
        id: column
        width: root.toastWidth
        spacing: 12

        // Smooths the shift when a toast above/below this one is added or
        // removed, mirroring BarPill's inner Row move Transition.
        move: Transition {
            NumberAnimation { properties: "y"; duration: Appearance.animMedium; easing.type: Easing.OutCubic }
        }

        Repeater {
            model: toastModel

            delegate: Item {
                id: toastWrapper
                required property int index
                required property string toastId
                required property string appName
                required property string summary
                required property string body

                width: root.toastWidth
                height: container.height
                clip: true

                Component.onCompleted: enterAnim.start()

                // alreadyOffscreen: the swipe gesture already slid the card
                // away (see NotificationCard's dismissAnim), so that path
                // only needs the container to collapse. The timeout path
                // hasn't moved yet and needs the full slide first.
                function dismiss(alreadyOffscreen) {
                    dismissTimer.stop()
                    if (alreadyOffscreen) {
                        collapseAnim.start()
                    } else {
                        slideOutThenCollapseAnim.start()
                    }
                }

                // Same tooltipBg token as ControlCenterWindow/
                // NotificationCenterWindow. Plain rounded corners (not the
                // drip treatment) since this floats free of any screen edge.
                Rectangle {
                    id: container
                    width: toastWrapper.width
                    height: card.implicitHeight
                    x: 0
                    radius: Appearance.controlCenterCornerRadius
                    color: Appearance.tooltipBg
                    clip: true

                    NotificationCard {
                        id: card
                        width: container.width
                        icon: "󰂚"
                        appName: toastWrapper.appName
                        summary: toastWrapper.summary
                        body: toastWrapper.body
                        // container above already supplies the black fill.
                        contentColor: "transparent"
                        onClosed: toastWrapper.dismiss(true)
                    }
                }

                ParallelAnimation {
                    id: enterAnim
                    NumberAnimation { target: container; property: "x"; from: root.toastWidth; to: 0; duration: Appearance.animMedium; easing.type: Easing.OutCubic }
                    NumberAnimation { target: toastWrapper; property: "opacity"; from: 0; to: 1; duration: Appearance.animMedium; easing.type: Easing.OutCubic }
                }

                // Timeout path: slide the container out first, then
                // collapse the leftover vertical space smoothly.
                SequentialAnimation {
                    id: slideOutThenCollapseAnim
                    ParallelAnimation {
                        NumberAnimation { target: container; property: "x"; to: root.toastWidth; duration: Appearance.animMedium; easing.type: Easing.OutCubic }
                        NumberAnimation { target: toastWrapper; property: "opacity"; to: 0; duration: Appearance.animMedium; easing.type: Easing.OutCubic }
                    }
                    NumberAnimation { target: toastWrapper; property: "height"; to: 0; duration: Appearance.animFast; easing.type: Easing.OutCubic }
                    onFinished: root.removeToast(toastWrapper.toastId)
                }

                // Swipe/X path: content's already gone, just fade and
                // collapse the empty shell.
                ParallelAnimation {
                    id: collapseAnim
                    NumberAnimation { target: container; property: "opacity"; to: 0; duration: Appearance.animFast; easing.type: Easing.OutCubic }
                    NumberAnimation { target: toastWrapper; property: "height"; to: 0; duration: Appearance.animFast; easing.type: Easing.OutCubic }
                    onFinished: root.removeToast(toastWrapper.toastId)
                }

                Timer {
                    id: dismissTimer
                    interval: root.autoDismissMs
                    running: true
                    onTriggered: toastWrapper.dismiss(false)
                }
            }
        }
    }
}

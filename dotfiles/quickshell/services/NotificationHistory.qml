pragma Singleton
import QtQuick
import Quickshell.Services.Notifications

QtObject {
    id: root

    property var history: []
    property bool dnd: false
    readonly property int unreadCount: history.filter(n => !n.read).length

    // Fired for every incoming notification regardless of dnd — whether a
    // toast actually renders is NotificationToastWindow's own call.
    signal notified(var entry)

    readonly property NotificationServer server: NotificationServer {
        keepOnReload: false

        onNotification: notification => {
            notification.tracked = true
            const entry = {
                id: notification.id,
                appName: notification.appName,
                summary: notification.summary,
                body: notification.body,
                // DND still logs it, just doesn't count as unread.
                read: root.dnd
            }
            root.history = [entry].concat(root.history).slice(0, 50)
            root.notified(entry)
        }
    }

    function markAllRead() {
        root.history = root.history.map(n => Object.assign({}, n, { read: true }))
    }

    function toggleDnd() {
        root.dnd = !root.dnd
    }

    function clear() {
        root.history = []
    }

    function dismiss(id) {
        root.history = root.history.filter(n => n.id !== id)
    }
}

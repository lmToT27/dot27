pragma Singleton
import QtQuick
import Quickshell.Services.Notifications

QtObject {
    id: root

    property var history: []
    property bool dnd: false
    readonly property int unreadCount: history.filter(n => !n.read).length

    property NotificationServer server: NotificationServer {
        keepOnReload: false

        onNotification: notification => {
            notification.tracked = true
            root.history = [{
                id: notification.id,
                appName: notification.appName,
                summary: notification.summary,
                body: notification.body,
                read: false
            }].concat(root.history).slice(0, 50)
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
}

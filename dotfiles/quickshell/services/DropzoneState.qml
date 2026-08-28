pragma Singleton
import QtQuick

// Single source of truth for files staged in the Dropzone — populated by
// external drag-and-drop onto DropzoneWindow, cleared by the user. No
// open/toggle/IpcHandler here: unlike the other panels this one is fully
// event-driven by Wayland pointer events, not a keybind-triggered popup.
QtObject {
    id: root

    property ListModel files: ListModel {}

    function addFile(url) {
        let urlStr = url.toString()
        if (urlStr.endsWith("/")) {
            urlStr = urlStr.slice(0, -1)
        }
        const fileName = decodeURIComponent(urlStr.split("/").pop())
        const isFolder = fileName.indexOf(".") === -1

        root.files.append({ fileUrl: url.toString(), fileName: fileName, isFolder: isFolder })
    }

    function removeFile(index) {
        root.files.remove(index)
    }

    function clear() {
        root.files.clear()
    }
}

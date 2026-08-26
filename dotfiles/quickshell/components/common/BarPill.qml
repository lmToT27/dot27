import QtQuick
import "../../config"

Rectangle {
    id: pill

    default property alias content: inner.data
    property alias spacing: inner.spacing

    property real cornerTopLeft: 0
    property real cornerTopRight: 0
    property real cornerBottomLeft: 0
    property real cornerBottomRight: 0

    color: Appearance.surface
    topLeftRadius: cornerTopLeft
    topRightRadius: cornerTopRight
    bottomLeftRadius: cornerBottomLeft
    bottomRightRadius: cornerBottomRight

    implicitWidth: inner.implicitWidth + Appearance.paddingH * 2
    implicitHeight: inner.implicitHeight + Appearance.paddingV * 2

    Row {
        id: inner
        anchors.centerIn: parent
        spacing: Appearance.moduleGap
    }
}

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Qt5Compat.GraphicalEffects
import "../../common"
import "../../../config"
import "../../../services"

// Row 2: a single full-width horizontal bar (replaces the old vertical
// MediaPlayerCard) — cover art on the left, title/artist filling the
// middle, transport controls on the right.
Rectangle {
    id: root

    Layout.fillWidth: true
    Layout.preferredHeight: 120
    radius: Appearance.radiusOuter
    color: Qt.rgba(1, 1, 1, 0.06)
    clip: true

    // Three-layer stack for a true pixel-level rounded+blurred backdrop:
    // `backdrop` (art + scrim, blurred by MultiEffect) and `bgMask` (a
    // plain rounded Rectangle) are both hidden sources; `OpacityMask` is
    // the only thing actually painted, clipping blurredBackdrop to
    // bgMask's rounded silhouette.
    //
    // `opacity: 0`, not `visible: false` — an invisible Image never
    // repaints when its `source` changes, which would freeze
    // OpacityMask's sampled texture instead of updating on track skips.
    Item {
        id: backdrop
        anchors.fill: parent
        opacity: 0

        // Full-opacity cover art — dimming happens entirely via the
        // overlay Rectangle below.
        Image {
            anchors.fill: parent
            source: Mpris.artUrl
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            visible: status === Image.Ready
        }

        // Dark scrim for text legibility over the art.
        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.6)
        }
    }

    MultiEffect {
        id: blurredBackdrop
        anchors.fill: backdrop
        source: backdrop
        opacity: 0
        blurEnabled: true
        // Tuned down from max so color and rough shapes from the art
        // stay recognizable instead of washing out to a flat tone.
        blur: 0.6
        blurMax: 32
    }

    Rectangle {
        id: bgMask
        anchors.fill: parent
        radius: root.radius
        opacity: 0
    }

    OpacityMask {
        anchors.fill: parent
        source: blurredBackdrop
        maskSource: bgMask
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 16

        Rectangle {
            id: artFrame
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: 64
            Layout.preferredHeight: 64
            radius: Appearance.radiusInner
            // Only shown directly while art hasn't loaded (behind the
            // fallback note icon below).
            color: Qt.rgba(1, 1, 1, 0.08)

            // Same true-clipping structure as the backdrop above: `art`
            // and `artMask` are the hidden source/mask pair, OpacityMask
            // is the only thing actually drawn.
            Image {
                id: art
                anchors.fill: parent
                source: Mpris.artUrl
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                opacity: 0
            }

            Rectangle {
                id: artMask
                anchors.fill: parent
                radius: artFrame.radius
                opacity: 0
            }

            OpacityMask {
                anchors.fill: parent
                source: art
                maskSource: artMask
                visible: art.status === Image.Ready
            }

            Text {
                anchors.centerIn: parent
                visible: art.status !== Image.Ready
                text: "󰎇"
                color: Theme.accent
                font.pixelSize: 26
                font.family: Appearance.fontFamily
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 4

            // Player badge (e.g. "SPOTIFY") — strips playerctl's DBus
            // service suffix (e.g. "firefox.instance1_2_3") after the
            // first "." and uppercases what's left.
            Rectangle {
                visible: Mpris.hasMedia && badgeLabel.text.length > 0
                Layout.preferredWidth: badgeLabel.implicitWidth + 12
                Layout.preferredHeight: badgeLabel.implicitHeight + 4
                radius: height / 2
                color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.18)

                Text {
                    id: badgeLabel
                    anchors.centerIn: parent
                    text: Mpris.playerName.split(".")[0].toUpperCase()
                    color: Theme.accent
                    font.bold: true
                    font.pixelSize: 9
                    font.family: Appearance.fontFamily
                }
            }

            MarqueeText {
                Layout.fillWidth: true
                text: Mpris.hasMedia ? Mpris.title : "No media playing"
                color: "white"
                font.bold: true
                font.pixelSize: 15
                font.family: Appearance.fontFamily
                active: Mpris.status === "Playing"
            }

            MarqueeText {
                Layout.fillWidth: true
                visible: Mpris.artist.length > 0
                text: Mpris.artist
                color: Qt.rgba(1, 1, 1, 0.7)
                font.family: Appearance.fontFamily
                active: Mpris.status === "Playing"
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignVCenter
            spacing: 18

            Text {
                Layout.alignment: Qt.AlignVCenter
                text: "󰒮"
                color: "white"
                font.pixelSize: 20
                font.family: Appearance.fontFamily
                MouseArea { anchors.fill: parent; anchors.margins: -6; onClicked: Mpris.previous() }
            }

            // Glow built from plain stacked circles instead of a
            // MultiEffect drop-shadow — three Rectangles centerIn'd on
            // the same parent are geometrically guaranteed concentric.
            Item {
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: 64
                Layout.preferredHeight: 64

                Rectangle {
                    anchors.centerIn: parent
                    width: 60
                    height: 60
                    radius: width / 2
                    color: Theme.accent
                    opacity: 0.16
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: 52
                    height: 52
                    radius: width / 2
                    color: Theme.accent
                    opacity: 0.28
                }

                Rectangle {
                    id: playButton
                    anchors.centerIn: parent
                    width: 44
                    height: 44
                    radius: width / 2
                    color: Theme.accent
                    scale: playMouseArea.pressed ? 0.92 : 1
                    Behavior on scale { NumberAnimation { duration: 100 } }

                    Text {
                        anchors.centerIn: parent
                        text: Mpris.status === "Playing" ? "󰏤" : "󰐊"
                        color: Theme.onAccent
                        font.pixelSize: 20
                        font.family: Appearance.fontFamily
                    }

                    MouseArea { id: playMouseArea; anchors.fill: parent; onClicked: Mpris.playPause() }
                }
            }

            Text {
                Layout.alignment: Qt.AlignVCenter
                text: "󰒭"
                color: "white"
                font.pixelSize: 20
                font.family: Appearance.fontFamily
                MouseArea { anchors.fill: parent; anchors.margins: -6; onClicked: Mpris.next() }
            }
        }
    }
}

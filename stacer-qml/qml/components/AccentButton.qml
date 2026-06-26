import QtQuick
import Stacer

// Primary action button: solid accent fill, navy text, rounded.
// When `busy`, shows an indeterminate shimmer sweep and ignores taps.
Rectangle {
    id: root

    property string text: ""
    property bool busy: false
    property string busyText: "Working…"
    signal clicked

    implicitHeight: 40
    implicitWidth: label.implicitWidth + 48
    radius: Theme.radiusBtn
    clip: true
    color: (hover.hovered && !busy) ? Theme.accentSoft : Theme.accent

    Behavior on color { ColorAnimation { duration: Theme.animFast } }
    scale: (tap.pressed && !busy) ? 0.985 : 1.0
    Behavior on scale { NumberAnimation { duration: Theme.animFast } }

    HoverHandler { id: hover; cursorShape: busy ? Qt.BusyCursor : Qt.PointingHandCursor }
    TapHandler { id: tap; enabled: !root.busy; onTapped: root.clicked() }

    // Indeterminate shimmer — a soft highlight sweeping left→right.
    Rectangle {
        id: sweep
        visible: root.busy
        height: parent.height
        width: parent.width * 0.45
        y: 0
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 0.5; color: Qt.rgba(1, 1, 1, 0.28) }
            GradientStop { position: 1.0; color: "transparent" }
        }
        x: -width
        NumberAnimation on x {
            running: root.busy
            from: -sweep.width
            to: root.width
            duration: 950
            loops: Animation.Infinite
        }
    }

    Row {
        anchors.centerIn: parent
        spacing: 8

        // Three pulsing dots while busy.
        Row {
            spacing: 4
            visible: root.busy
            anchors.verticalCenter: parent.verticalCenter
            Repeater {
                model: 3
                Rectangle {
                    width: 5; height: 5; radius: 2.5
                    color: Theme.accentText
                    SequentialAnimation on opacity {
                        running: root.busy
                        loops: Animation.Infinite
                        PauseAnimation { duration: index * 160 }
                        NumberAnimation { from: 0.3; to: 1.0; duration: 320 }
                        NumberAnimation { from: 1.0; to: 0.3; duration: 320 }
                        PauseAnimation { duration: (2 - index) * 160 }
                    }
                }
            }
        }

        Text {
            id: label
            anchors.verticalCenter: parent.verticalCenter
            text: root.busy ? root.busyText : root.text
            color: Theme.accentText
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fsBody
            font.weight: Theme.weightMedium
        }
    }
}

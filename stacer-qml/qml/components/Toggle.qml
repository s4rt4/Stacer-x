import QtQuick
import Stacer

// Compact on/off switch. Emits `toggled(bool)` on click; `checked` is the
// current visual state (set by the owner from real data).
Item {
    id: root

    property bool checked: false
    signal toggled(bool value)

    implicitWidth: 38
    implicitHeight: 20

    Rectangle {
        id: track
        anchors.fill: parent
        radius: height / 2
        color: root.checked ? Theme.accent : Theme.cardHover
        Behavior on color { ColorAnimation { duration: Theme.animFast } }

        Rectangle {
            id: knob
            width: 16; height: 16; radius: 8
            color: root.checked ? Theme.accentText : Theme.textDim
            anchors.verticalCenter: parent.verticalCenter
            x: root.checked ? parent.width - width - 2 : 2
            Behavior on x { NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: Theme.animFast } }
        }
    }

    HoverHandler { cursorShape: Qt.PointingHandCursor }
    TapHandler { onTapped: root.toggled(!root.checked) }
}

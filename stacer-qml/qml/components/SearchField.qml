import QtQuick
import Stacer

// Compact search box: magnifier icon + text input + clear button.
Rectangle {
    id: root

    property alias text: input.text
    property string placeholder: "Search"

    implicitWidth: 200
    implicitHeight: 32
    radius: Theme.radiusBtn
    color: Theme.card
    border.width: 1
    border.color: input.activeFocus ? Theme.accent : Theme.border

    Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

    Row {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 8
        spacing: 8

        IconImage {
            anchors.verticalCenter: parent.verticalCenter
            source: Theme.icon("search")
            size: 15
            color: Theme.textDim
        }

        Item {
            width: parent.width - 15 - 8 - (clear.visible ? clear.width + 8 : 0)
            height: parent.height

            TextInput {
                id: input
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fsBody
                selectionColor: Theme.accent
                selectedTextColor: Theme.accentText
                clip: true
                verticalAlignment: TextInput.AlignVCenter

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.placeholder
                    color: Theme.textDim
                    font: input.font
                    visible: input.text.length === 0 && !input.activeFocus
                }
            }
        }

        IconImage {
            id: clear
            anchors.verticalCenter: parent.verticalCenter
            source: Theme.icon("x")
            size: 14
            color: clearHover.hovered ? Theme.text : Theme.textDim
            visible: input.text.length > 0
            HoverHandler { id: clearHover; cursorShape: Qt.PointingHandCursor }
            TapHandler { onTapped: input.text = "" }
        }
    }
}

import QtQuick
import Stacer

// 2x2 grid tile: header (name left, icon right), then label over value.
Card {
    id: root

    property string name: ""
    property url iconSource
    property string label: ""
    property string value: ""

    hoverable: true

    Item {
        anchors.fill: parent

        Text {
            id: nameText
            anchors.top: parent.top
            anchors.left: parent.left
            text: root.name
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fsBody
            font.weight: Theme.weightMedium
        }

        IconImage {
            anchors.top: parent.top
            anchors.right: parent.right
            source: root.iconSource
            size: 17
            color: Theme.textDim
        }

        Text {
            id: lblText
            anchors.left: parent.left
            anchors.bottom: valText.top
            anchors.bottomMargin: 2
            text: root.label
            color: Theme.textDim
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fsSmall
        }

        Text {
            id: valText
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            text: root.value
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fsBody
        }
    }
}

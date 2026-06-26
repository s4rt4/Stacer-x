import QtQuick
import Stacer

// A metric in the boost card: small vertical accent strip + number over label.
Row {
    id: root

    property string value: ""
    property string label: ""

    spacing: 10

    Rectangle {
        width: 4
        height: 32
        radius: 2
        color: Theme.accent
        anchors.verticalCenter: parent.verticalCenter
    }

    Column {
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        Text {
            text: root.value
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fsMetric
            font.weight: Theme.weightMedium
        }

        Text {
            text: root.label
            color: Theme.textDim
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fsSmall
        }
    }
}

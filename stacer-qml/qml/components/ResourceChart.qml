import QtQuick
import QtQuick.Layouts
import Stacer

// Card with a title, a current-value readout, and a live sparkline.
Card {
    id: root

    property string title: ""
    property string value: ""
    property var values: []
    property real maxValue: 0
    property color accent: Theme.accent
    property url iconSource

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            IconImage {
                anchors.verticalCenter: parent.verticalCenter
                source: root.iconSource
                size: 17
                color: root.accent
                visible: root.iconSource != ""
            }
            Text {
                text: root.title
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fsTitle
                font.weight: Theme.weightMedium
            }
            Item { Layout.fillWidth: true }
            Text {
                text: root.value
                color: root.accent
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fsBody
                font.weight: Theme.weightMedium
            }
        }

        Sparkline {
            Layout.fillWidth: true
            Layout.fillHeight: true
            values: root.values
            maxValue: root.maxValue
            lineColor: root.accent
        }
    }
}

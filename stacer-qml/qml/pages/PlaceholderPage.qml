import QtQuick
import Stacer

// Generic page for sections not yet ported to QML. Keeps the shell coherent.
Item {
    id: page

    property string title: ""
    property url iconSource

    Card {
        anchors.centerIn: parent
        width: Math.min(parent.width - Theme.padCard * 2, 360)
        implicitHeight: col.implicitHeight + padding * 2

        Column {
            id: col
            anchors.centerIn: parent
            spacing: 10

            IconImage {
                anchors.horizontalCenter: parent.horizontalCenter
                source: page.iconSource
                size: 32
                color: Theme.accentSoft
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: page.title
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fsTitle
                font.weight: Theme.weightMedium
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Coming soon to the new interface"
                color: Theme.textDim
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fsBody
            }
        }
    }
}

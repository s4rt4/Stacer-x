import QtQuick
import Stacer

// Hero card: icon thumb + title + subtitle with an actionable link.
Card {
    id: root

    property string title: ""
    property string subtitle: ""
    property string linkText: ""
    property url iconSource: Theme.icon("sparkles")
    property color iconColor: Theme.warn

    // Emitted when the link is clicked. Only shown when linkText is set.
    signal linkActivated()

    implicitHeight: row.implicitHeight + padding * 2

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 14

        Rectangle {
            width: 40
            height: 40
            radius: 9
            color: Theme.cardHover
            anchors.verticalCenter: parent.verticalCenter

            IconImage {
                anchors.centerIn: parent
                source: root.iconSource
                size: 21
                color: root.iconColor
            }
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            Text {
                text: root.title
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fsTitle
                font.weight: Theme.weightMedium
            }

            Row {
                spacing: 6
                Text {
                    text: root.subtitle
                    color: Theme.textDim
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                }
                Text {
                    id: link
                    text: root.linkText
                    color: linkHover.hovered ? Theme.accent : Theme.accentSoft
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    font.underline: linkHover.hovered
                    visible: root.linkText.length > 0

                    HoverHandler { id: linkHover; cursorShape: Qt.PointingHandCursor }
                    TapHandler { onTapped: root.linkActivated() }
                }
            }
        }
    }
}

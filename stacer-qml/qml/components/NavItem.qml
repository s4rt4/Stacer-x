import QtQuick
import QtQuick.Controls.Basic
import Stacer

// Icon-only sidebar nav item. The label shows as a themed tooltip on hover.
Rectangle {
    id: root

    property url icon
    property string label
    property bool active: false
    signal clicked

    radius: Theme.radiusNav
    implicitHeight: 46

    color: active ? Theme.card
                  : (hover.hovered ? Theme.cardHover : "transparent")

    Behavior on color { ColorAnimation { duration: Theme.animFast } }

    readonly property color fg: active ? Theme.accentSoft : Theme.textDim

    HoverHandler {
        id: hover
        cursorShape: Qt.PointingHandCursor
        onHoveredChanged: hovered ? tip.open() : tip.close()
    }
    TapHandler { onTapped: root.clicked() }

    IconImage {
        anchors.centerIn: parent
        source: root.icon
        size: 20
        color: root.fg
    }

    // Active accent strip on the left edge.
    Rectangle {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: 3
        height: parent.height * 0.5
        radius: 2
        color: Theme.accent
        visible: root.active
    }

    Popup {
        id: tip
        x: root.width + 10
        y: (root.height - height) / 2
        padding: 0
        closePolicy: Popup.NoAutoClose
        background: Rectangle {
            color: Theme.card
            radius: 6
            border.width: 1
            border.color: Theme.border
        }
        contentItem: Text {
            text: root.label
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fsBody
            leftPadding: 11; rightPadding: 11; topPadding: 6; bottomPadding: 6
        }
    }
}

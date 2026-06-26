import QtQuick
import Stacer

// A single window control (minimize / maximize / close), drawn with shapes
// so it needs no icon assets and stays crisp at any DPI.
Rectangle {
    id: root

    property string kind: "min"   // "min" | "max" | "close"
    property bool danger: false
    signal clicked

    width: 34
    height: 30
    radius: 6
    color: hover.hovered ? (danger ? "#c4344a" : Theme.cardHover) : "transparent"

    Behavior on color { ColorAnimation { duration: Theme.animFast } }

    readonly property color fg: (hover.hovered && danger) ? "white" : Theme.textDim

    HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
    TapHandler { onTapped: root.clicked() }

    // minimize — single line
    Rectangle {
        visible: root.kind === "min"
        width: 11; height: 1.5
        color: root.fg
        anchors.centerIn: parent
    }

    // maximize — square outline
    Rectangle {
        visible: root.kind === "max"
        width: 10; height: 10; radius: 1.5
        color: "transparent"
        border.color: root.fg
        border.width: 1.5
        anchors.centerIn: parent
    }

    // close — X
    Item {
        visible: root.kind === "close"
        anchors.centerIn: parent
        width: 12; height: 12
        Rectangle { width: 13; height: 1.5; radius: 1; color: root.fg; anchors.centerIn: parent; rotation: 45 }
        Rectangle { width: 13; height: 1.5; radius: 1; color: root.fg; anchors.centerIn: parent; rotation: -45 }
    }
}

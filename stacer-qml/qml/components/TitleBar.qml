import QtQuick
import Stacer

// Custom dark title bar (frameless window). Drag to move, double-click to
// maximize, with minimize / maximize / close controls on the right.
Rectangle {
    id: bar

    required property var win

    height: 44
    color: Theme.sidebar

    // Drag region — stops short of the window controls so a press on
    // minimize/close is never swallowed as a window-move on the compositor.
    MouseArea {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: controls.left
        onPressed: bar.win.startSystemMove()
    }

    Row {
        anchors.left: parent.left
        anchors.leftMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8

        Logo {
            anchors.verticalCenter: parent.verticalCenter
            size: 22
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "Stacer-X"
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fsBody
            font.weight: Theme.weightMedium
        }
    }

    Row {
        id: controls
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        WinButton { kind: "min";   onClicked: bar.win.showMinimized() }
        WinButton { kind: "close"; danger: true; onClicked: bar.win.close() }
    }
}

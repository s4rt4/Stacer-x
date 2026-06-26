import QtQuick
import Stacer

// Left navigation rail. `model` is a flat list of { icon, label, bottom }.
// Items flagged `bottom: true` are pinned to the bottom group (Settings/About).
Rectangle {
    id: root

    property var model: []
    property int currentIndex: 0
    signal navigate(int index)

    color: Theme.sidebar
    implicitWidth: Theme.sidebarW

    Column {
        id: topGroup
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: 10
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        spacing: 4

        Repeater {
            model: root.model
            delegate: NavItem {
                required property var modelData
                required property int index
                visible: !(modelData.bottom === true)
                height: visible ? implicitHeight : 0
                width: topGroup.width
                icon: Theme.icon(modelData.icon)
                label: modelData.label
                active: root.currentIndex === index
                onClicked: root.navigate(index)
            }
        }
    }

    Column {
        id: bottomGroup
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottomMargin: 14
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        spacing: 4

        Repeater {
            model: root.model
            delegate: NavItem {
                required property var modelData
                required property int index
                visible: modelData.bottom === true
                height: visible ? implicitHeight : 0
                width: bottomGroup.width
                icon: Theme.icon(modelData.icon)
                label: modelData.label
                active: root.currentIndex === index
                onClicked: root.navigate(index)
            }
        }
    }
}

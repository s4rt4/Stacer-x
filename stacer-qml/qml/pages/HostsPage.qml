import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import Stacer

// /etc/hosts editor backed by the `hosts` controller. Toggle, remove or add
// host entries (writes are elevated).
Item {
    id: page

    onVisibleChanged: hosts.setActive(visible)
    Component.onCompleted: if (visible) hosts.setActive(true)

    component Field: Rectangle {
        property alias text: input.text
        property string placeholder: ""
        implicitHeight: 34
        radius: Theme.radiusBtn
        color: Theme.card
        border.width: 1
        border.color: input.activeFocus ? Theme.accent : Theme.border
        Behavior on border.color { ColorAnimation { duration: Theme.animFast } }
        TextInput {
            id: input
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            verticalAlignment: TextInput.AlignVCenter
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fsBody
            selectionColor: Theme.accent
            selectedTextColor: Theme.accentText
            clip: true
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: parent.parent.placeholder
                color: Theme.textDim
                font: input.font
                visible: input.text.length === 0
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.padCard
        spacing: Theme.gap

        // ---- Header ----
        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "Hosts"
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fsTitle
                font.weight: Theme.weightMedium
            }
            Item { Layout.fillWidth: true }
            BusyIndicator { running: hosts.busy; visible: hosts.busy; implicitWidth: 20; implicitHeight: 20 }
            Text {
                text: hosts.count + " entries"
                color: Theme.textDim
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fsBody
            }
        }

        // ---- Add entry ----
        Card {
            Layout.fillWidth: true
            implicitHeight: 34 + padding * 2

            RowLayout {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                Field { id: ipField;   Layout.preferredWidth: 140; placeholder: "IP address" }
                Field { id: hostField; Layout.fillWidth: true;      placeholder: "Hostname" }
                AccentButton {
                    text: "Add"
                    busy: hosts.busy
                    busyText: "Saving…"
                    onClicked: {
                        hosts.addEntry(ipField.text, hostField.text)
                        ipField.text = ""
                        hostField.text = ""
                    }
                }
            }
        }

        // ---- List ----
        Card {
            Layout.fillWidth: true
            Layout.fillHeight: true
            padding: 8

            ListView {
                anchors.fill: parent
                clip: true
                model: hosts
                boundsBehavior: Flickable.StopAtBounds
                ScrollBar.vertical: ScrollBar { }

                delegate: Rectangle {
                    id: row
                    required property int index
                    required property string ip
                    required property string host
                    required property bool enabled

                    width: ListView.view.width
                    height: 44
                    radius: 6
                    color: hover.hovered ? Theme.cardHover : "transparent"

                    HoverHandler { id: hover }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 12

                        Text {
                            text: row.ip
                            color: row.enabled ? Theme.accentSoft : Theme.textDim
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fsBody
                            Layout.preferredWidth: 130
                            elide: Text.ElideRight
                        }
                        Text {
                            Layout.fillWidth: true
                            text: row.host
                            color: row.enabled ? Theme.text : Theme.textDim
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fsBody
                            elide: Text.ElideRight
                        }
                        Toggle {
                            checked: row.enabled
                            onToggled: hosts.toggle(row.index)
                        }
                        WinButton {
                            kind: "close"
                            danger: true
                            opacity: hover.hovered ? 1 : 0.25
                            Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
                            onClicked: hosts.removeEntry(row.index)
                        }
                    }
                }
            }
        }
    }
}

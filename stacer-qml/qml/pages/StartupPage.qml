import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import Stacer

// Autostart applications backed by the `startup` controller. User-level edits
// to ~/.config/autostart — toggle on/off or remove an entry.
Item {
    id: page

    onVisibleChanged: startup.setActive(visible)
    Component.onCompleted: if (visible) startup.setActive(true)

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.padCard
        spacing: Theme.gap

        // ---- Header ----
        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "Startup applications"
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fsTitle
                font.weight: Theme.weightMedium
            }
            Item { Layout.fillWidth: true }
            Text {
                text: startup.count + " apps"
                color: Theme.textDim
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fsBody
            }
        }

        // ---- List card ----
        Card {
            Layout.fillWidth: true
            Layout.fillHeight: true
            padding: 8

            // Empty state
            Column {
                anchors.centerIn: parent
                spacing: 10
                visible: startup.count === 0
                IconImage {
                    anchors.horizontalCenter: parent.horizontalCenter
                    source: Theme.icon("power"); size: 30; color: Theme.textDim
                }
                Text {
                    text: "No startup applications"
                    color: Theme.textDim
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fsBody
                }
            }

            ListView {
                id: list
                anchors.fill: parent
                clip: true
                model: startup
                visible: startup.count > 0
                boundsBehavior: Flickable.StopAtBounds
                spacing: 2
                ScrollBar.vertical: ScrollBar { }

                delegate: Rectangle {
                    id: row
                    required property string name
                    required property bool enabled
                    required property string path

                    width: ListView.view.width
                    height: 48
                    radius: 6
                    // Instant hover (see ProcessesPage) — no trailing highlight.
                    color: hover.hovered ? Theme.cardHover : "transparent"

                    HoverHandler { id: hover }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 12

                        Rectangle {
                            width: 30; height: 30; radius: 8
                            color: Theme.card
                            IconImage {
                                anchors.centerIn: parent
                                source: Theme.icon("rocket")
                                size: 16
                                color: row.enabled ? Theme.accentSoft : Theme.textDim
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: row.name
                            color: row.enabled ? Theme.text : Theme.textDim
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fsBody
                            font.weight: Theme.weightMedium
                            elide: Text.ElideRight
                        }

                        Toggle {
                            checked: row.enabled
                            onToggled: (v) => startup.setEnabled(row.path, v)
                        }

                        WinButton {
                            kind: "close"
                            danger: true
                            opacity: hover.hovered ? 1 : 0.25
                            Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
                            onClicked: startup.removeApp(row.path)
                        }
                    }
                }
            }
        }
    }
}

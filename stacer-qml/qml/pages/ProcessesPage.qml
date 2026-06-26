import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import Stacer

// Live process list backed by the `processes` controller (QAbstractListModel).
// Polls only while visible; sorted by CPU usage.
Item {
    id: page

    // Drive the controller's polling by page visibility.
    onVisibleChanged: processes.setActive(visible)
    Component.onCompleted: if (visible) processes.setActive(true)

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.padCard
        spacing: Theme.gap

        // ---- Header ----
        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            Text {
                text: "Processes"
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fsTitle
                font.weight: Theme.weightMedium
            }
            Item { Layout.fillWidth: true }
            Text {
                text: processes.count + " running"
                color: Theme.textDim
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fsBody
            }
            SearchField {
                Layout.preferredWidth: 200
                placeholder: "Search processes"
                onTextChanged: processes.filter = text
            }
        }

        // ---- List card ----
        Card {
            Layout.fillWidth: true
            Layout.fillHeight: true
            padding: 8

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                // column headers
                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 8
                    Layout.rightMargin: 8
                    Layout.bottomMargin: 6
                    Layout.topMargin: 4
                    spacing: 12
                    Text {
                        text: "Process"; color: Theme.textDim
                        font.family: Theme.fontFamily; font.pixelSize: Theme.fsSmall
                        Layout.fillWidth: true
                    }
                    Text {
                        text: "CPU"; color: Theme.textDim
                        font.family: Theme.fontFamily; font.pixelSize: Theme.fsSmall
                        horizontalAlignment: Text.AlignRight; Layout.preferredWidth: 56
                    }
                    Text {
                        text: "Memory"; color: Theme.textDim
                        font.family: Theme.fontFamily; font.pixelSize: Theme.fsSmall
                        horizontalAlignment: Text.AlignRight; Layout.preferredWidth: 84
                    }
                    Text {
                        text: "Priority"; color: Theme.textDim
                        font.family: Theme.fontFamily; font.pixelSize: Theme.fsSmall
                        horizontalAlignment: Text.AlignHCenter; Layout.preferredWidth: 44
                    }
                    Item { Layout.preferredWidth: 34 }
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: Theme.border }

                ListView {
                    id: list
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    model: processes
                    boundsBehavior: Flickable.StopAtBounds
                    ScrollBar.vertical: ScrollBar { }

                    delegate: Rectangle {
                        id: row
                        required property int pid
                        required property string cmd
                        required property string uname
                        required property real pcpu
                        required property string mem
                        required property int nice
                        required property string state

                        width: ListView.view.width
                        height: 38
                        radius: 6
                        // Instant hover — animating it makes fast pointer moves
                        // leave a trailing highlight on the row just left.
                        color: hover.hovered ? Theme.cardHover : "transparent"

                        HoverHandler { id: hover }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 12

                            Column {
                                Layout.fillWidth: true
                                spacing: 1
                                Text {
                                    text: row.cmd
                                    color: Theme.text
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fsBody
                                    elide: Text.ElideRight
                                    width: parent.width
                                }
                                Text {
                                    text: row.uname
                                    color: Theme.textDim
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fsSmall
                                }
                            }

                            Text {
                                text: row.pcpu.toFixed(1) + "%"
                                color: row.pcpu > 20 ? Theme.accentSoft : Theme.text
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fsBody
                                horizontalAlignment: Text.AlignRight
                                Layout.preferredWidth: 56
                            }
                            Text {
                                text: row.mem
                                color: Theme.text
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fsBody
                                horizontalAlignment: Text.AlignRight
                                Layout.preferredWidth: 84
                            }

                            // Priority (nice) — click to renice.
                            Rectangle {
                                Layout.preferredWidth: 44
                                Layout.preferredHeight: 22
                                radius: 6
                                color: prioHover.hovered ? Theme.cardHover : Theme.bg
                                Text {
                                    anchors.centerIn: parent
                                    text: row.nice
                                    color: row.nice < 0 ? Theme.accentSoft : Theme.textDim
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fsSmall
                                }
                                HoverHandler { id: prioHover; cursorShape: Qt.PointingHandCursor }
                                TapHandler { onTapped: prioMenu.popup() }
                                Menu {
                                    id: prioMenu
                                    MenuItem { text: "High priority (−5)"; onTriggered: processes.setPriority(row.pid, -5) }
                                    MenuItem { text: "Normal (0)";         onTriggered: processes.setPriority(row.pid, 0) }
                                    MenuItem { text: "Low priority (+10)"; onTriggered: processes.setPriority(row.pid, 10) }
                                }
                            }

                            WinButton {
                                kind: "close"
                                danger: true
                                opacity: hover.hovered ? 1 : 0.25
                                Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
                                onClicked: processes.killProcess(row.pid)
                            }
                        }
                    }
                }
            }
        }
    }
}

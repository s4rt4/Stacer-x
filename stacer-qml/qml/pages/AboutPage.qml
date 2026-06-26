import QtQuick
import QtQuick.Layouts
import Stacer

// About — showcases the brand logo with app identity and credits.
Item {
    id: page

    ColumnLayout {
        anchors.centerIn: parent
        width: Math.min(parent.width - Theme.padCard * 2, 380)
        spacing: 14

        Logo {
            Layout.alignment: Qt.AlignHCenter
            size: 96
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "Stacer-X"
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: 22
            font.weight: Theme.weightMedium
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "Linux system optimizer · version 1.7.0"
            color: Theme.textDim
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fsBody
        }

        Card {
            Layout.fillWidth: true
            Layout.topMargin: 6
            implicitHeight: sysCol.implicitHeight + padding * 2

            ColumnLayout {
                id: sysCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                spacing: 7

                Repeater {
                    model: [
                        { k: "Host",      v: system.hostname },
                        { k: "OS",        v: system.distribution },
                        { k: "Kernel",    v: system.kernel },
                        { k: "Processor", v: system.cpuModel },
                        { k: "Cores",     v: system.cpuCore },
                        { k: "Uptime",    v: system.uptimeText }
                    ]
                    delegate: RowLayout {
                        required property var modelData
                        Layout.fillWidth: true
                        spacing: 12
                        Text {
                            text: modelData.k
                            color: Theme.textDim
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fsBody
                            Layout.preferredWidth: 80
                        }
                        Text {
                            Layout.fillWidth: true
                            text: modelData.v
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fsBody
                            horizontalAlignment: Text.AlignRight
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }

        Card {
            Layout.fillWidth: true
            implicitHeight: creditsCol.implicitHeight + padding * 2

            ColumnLayout {
                id: creditsCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                spacing: 6

                Text {
                    text: "Reborn with a Qt Quick interface, styled after Microsoft PC Manager."
                    color: Theme.textDim
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fsBody
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
                Text {
                    text: "Original by oguzhaninan · Qt6 fork by QuentiumYT · GPL licensed."
                    color: Theme.textDim
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fsSmall
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }
        }
    }
}

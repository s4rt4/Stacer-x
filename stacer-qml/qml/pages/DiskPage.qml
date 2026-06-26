import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import Stacer

// Disk usage overview: a donut of partition sizes plus a per-partition legend.
// Reuses the `resmon` controller's disk data.
Item {
    id: page

    onVisibleChanged: resmon.setActive(visible)
    Component.onCompleted: if (visible) resmon.setActive(true)

    readonly property var palette: ["#5cc4ef", "#c9a0ff", "#f0c060", "#76b900",
                                     "#6fcdf2", "#ff7eb6", "#7ee787", "#ffa657"]

    // Slices proportional to each partition's total size.
    readonly property var slices: {
        var arr = []
        var d = resmon.disks
        for (var i = 0; i < d.length; ++i)
            arr.push({ value: d[i].sizeBytes, color: palette[i % palette.length] })
        return arr
    }

    ScrollView {
        anchors.fill: parent
        anchors.margins: Theme.padCard
        contentWidth: availableWidth
        clip: true
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

        ColumnLayout {
            width: page.width - Theme.padCard * 2
            spacing: Theme.gap

            Text {
                text: "Disk"
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fsTitle
                font.weight: Theme.weightMedium
            }

            Card {
                Layout.fillWidth: true
                implicitHeight: Math.max(190, legendCol.implicitHeight) + padding * 2

                RowLayout {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 20

                    // Donut + center count
                    Item {
                        Layout.preferredWidth: 170
                        Layout.preferredHeight: 170
                        PieChart {
                            anchors.fill: parent
                            slices: page.slices
                            holeColor: Theme.card
                        }
                        Column {
                            anchors.centerIn: parent
                            spacing: 0
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: resmon.disks.length
                                color: Theme.text
                                font.family: Theme.fontFamily
                                font.pixelSize: 26
                                font.weight: Theme.weightMedium
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: resmon.disks.length === 1 ? "partition" : "partitions"
                                color: Theme.textDim
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fsSmall
                            }
                        }
                    }

                    // Legend
                    ColumnLayout {
                        id: legendCol
                        Layout.fillWidth: true
                        spacing: 12

                        Repeater {
                            model: resmon.disks
                            delegate: RowLayout {
                                required property int index
                                required property var modelData
                                Layout.fillWidth: true
                                spacing: 10

                                Rectangle {
                                    width: 12; height: 12; radius: 3
                                    color: page.palette[index % page.palette.length]
                                    Layout.alignment: Qt.AlignVCenter
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 3
                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text {
                                            Layout.fillWidth: true
                                            text: modelData.name + "   " + modelData.device
                                            color: Theme.text
                                            font.family: Theme.fontFamily
                                            font.pixelSize: Theme.fsBody
                                            font.weight: Theme.weightMedium
                                            elide: Text.ElideRight
                                        }
                                        Text {
                                            text: modelData.usedText + " / " + modelData.totalText
                                                  + "  (" + modelData.percent + "%)"
                                            color: Theme.textDim
                                            font.family: Theme.fontFamily
                                            font.pixelSize: Theme.fsSmall
                                        }
                                    }
                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 6; radius: 3
                                        color: Theme.bg
                                        Rectangle {
                                            anchors.left: parent.left
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: parent.width * modelData.percent / 100
                                            height: parent.height; radius: 3
                                            color: modelData.percent > 90 ? Theme.warn
                                                 : page.palette[index % page.palette.length]
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

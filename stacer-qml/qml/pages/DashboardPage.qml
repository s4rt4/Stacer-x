import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import QtQuick.Window
import Stacer

// Dashboard — mirrors mockup-stacer.html. Live numbers come from the
// `system` controller (SystemController) exposed as a context property.
Item {
    id: page

    // Transient result message shown after a boost completes.
    property string boostMsg: ""

    Connections {
        target: system
        function onBoostFinished() {
            page.boostMsg = system.lastBoostFreedBytes > 0
                ? "Freed " + system.lastBoostFreedText + " of memory · usage now " + system.memPercent + "%"
                : "Already optimized · memory usage " + system.memPercent + "%"
            boostMsgTimer.restart()
        }
    }
    Timer { id: boostMsgTimer; interval: 6000; onTriggered: page.boostMsg = "" }

    ScrollView {
        anchors.fill: parent
        anchors.margins: Theme.padCard
        contentWidth: availableWidth
        clip: true
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

    ColumnLayout {
        width: page.width - Theme.padCard * 2
        spacing: Theme.gap

        // ---- Hero: live status + contextual recommendation ----
        // State is derived from current metrics; the link performs a real
        // action (free memory, or jump to the page that fixes the issue).
        //   0 = memory pressure, 1 = disk almost full, 2 = healthy
        HeroBanner {
            Layout.fillWidth: true

            readonly property int state: system.memPercent >= 85 ? 0
                                       : system.rootPercent >= 90 ? 1 : 2

            iconSource: state === 2 ? Theme.icon("circle-gauge") : Theme.icon("sparkles")
            iconColor: state === 0 ? Theme.warn
                     : state === 1 ? Theme.danger
                     : Theme.good

            title: state === 0 ? "Memory is filling up"
                 : state === 1 ? "Disk is almost full"
                 : "Your system is healthy"

            subtitle: state === 0 ? "RAM is at " + system.memPercent + "% — free it to speed things up."
                    : state === 1 ? "Root disk is " + system.rootPercent + "% full — clear some space."
                    : "RAM " + system.memPercent + "% · Disk " + system.rootPercent + "% · up " + system.uptimeText

            linkText: state === 0 ? "Free memory now ›"
                    : state === 1 ? "Open Cleaner ›"
                    : ""

            onLinkActivated: {
                if (state === 0)
                    system.boost()
                else if (state === 1)
                    Window.window.currentIndex = 1   // Cleaner
            }
        }

        // ---- System boost ----
        Card {
            Layout.fillWidth: true
            implicitHeight: boostCol.implicitHeight + padding * 2

            ColumnLayout {
                id: boostCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                spacing: 0

                RowLayout {
                    Layout.fillWidth: true
                    Row {
                        spacing: 8
                        IconImage {
                            anchors.verticalCenter: parent.verticalCenter
                            source: Theme.icon("rocket"); size: 17; color: Theme.accentSoft
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "System boost"
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fsTitle
                            font.weight: Theme.weightMedium
                        }
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: "Smart boost"
                        color: Theme.accentSoft
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                    }
                }

                Text {
                    text: "Up " + system.uptimeText + "  ·  free up your system resources"
                    color: Theme.textDim
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    topPadding: 2
                    bottomPadding: 14
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 32
                    BoostMetric {
                        value: system.memPercent + "%"
                        label: "Memory usage"
                    }
                    BoostMetric {
                        value: system.rootUsedText
                        label: "Disk used (/)"
                    }
                    Item { Layout.fillWidth: true }
                }

                AccentButton {
                    Layout.topMargin: 14
                    Layout.fillWidth: true
                    text: "Boost"
                    busy: system.boosting
                    busyText: "Boosting…"
                    onClicked: system.boost()
                }

                // Result banner — slides open after a boost, then auto-hides.
                Rectangle {
                    id: boostBanner
                    Layout.fillWidth: true
                    Layout.topMargin: page.boostMsg !== "" ? 12 : 0
                    radius: Theme.radiusBtn
                    clip: true
                    color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.13)
                    implicitHeight: page.boostMsg !== "" ? 40 : 0
                    opacity: page.boostMsg !== "" ? 1 : 0

                    Behavior on implicitHeight { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                    Behavior on opacity { NumberAnimation { duration: 220 } }

                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 10

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "✓"
                            color: Theme.accentSoft
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fsTitle
                            font.weight: Theme.weightMedium
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: page.boostMsg
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fsBody
                        }
                    }
                }
            }
        }

        // ---- Feature grid 2x2 ----
        GridLayout {
            Layout.fillWidth: true
            columns: 2
            rowSpacing: Theme.gap
            columnSpacing: Theme.gap

            FeatureTile {
                Layout.fillWidth: true
                Layout.preferredHeight: 92
                name: "Processor"
                iconSource: Theme.icon("cpu")
                label: "Usage · clock"
                value: system.cpuPercent + "%  ·  " + system.cpuClockText
            }
            FeatureTile {
                Layout.fillWidth: true
                Layout.preferredHeight: 92
                name: "Memory"
                iconSource: Theme.icon("memory-stick")
                label: "In use"
                value: system.memUsedText + " / " + system.memTotalText
            }
            FeatureTile {
                Layout.fillWidth: true
                Layout.preferredHeight: 92
                name: "Deep cleanup"
                iconSource: Theme.icon("eraser")
                label: "Root (/)"
                value: system.rootUsedText + " / " + system.rootTotalText
            }
            FeatureTile {
                Layout.fillWidth: true
                Layout.preferredHeight: 92
                name: "System"
                iconSource: Theme.icon("laptop")
                label: system.distribution
                value: system.hostname + "  ·  " + system.kernel
            }
        }

        // ---- CPU cores ----
        Card {
            Layout.fillWidth: true
            implicitHeight: coresCol.implicitHeight + padding * 2

            ColumnLayout {
                id: coresCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    IconImage { source: Theme.icon("microchip"); size: 17; color: Theme.accent; anchors.verticalCenter: parent.verticalCenter }
                    Text {
                        text: "CPU cores"
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fsTitle
                        font.weight: Theme.weightMedium
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: "load  " + system.loadText
                        color: Theme.textDim
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fsBody
                    }
                }

                Flow {
                    Layout.fillWidth: true
                    spacing: 6
                    Repeater {
                        model: system.cores
                        delegate: Rectangle {
                            required property var modelData
                            width: 26; height: 40; radius: 4
                            color: Theme.bg
                            Rectangle {
                                anchors.bottom: parent.bottom
                                anchors.left: parent.left
                                anchors.right: parent.right
                                height: parent.height * Math.max(0, Math.min(modelData, 100)) / 100
                                radius: 4
                                color: modelData > 80 ? Theme.warn : Theme.accent
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: 2
                                text: modelData
                                color: Theme.text
                                font.family: Theme.fontFamily
                                font.pixelSize: 9
                            }
                        }
                    }
                }
            }
        }

    }
    }
}

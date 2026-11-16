import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import Stacer

// App preferences backed by the `settings` controller.
Item {
    id: page

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
            text: qsTr("Settings")
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fsTitle
            font.weight: Theme.weightMedium
        }

        // Language names remain readable in both locales.
        Card {
            Layout.fillWidth: true
            implicitHeight: languageRow.implicitHeight + padding * 2

            RowLayout {
                id: languageRow
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                spacing: 12

                Column {
                    Layout.fillWidth: true
                    spacing: 1
                    Text {
                        text: qsTr("Language")
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fsBody
                        font.weight: Theme.weightMedium
                    }
                    Text {
                        text: qsTr("Choose the display language")
                        color: Theme.textDim
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fsSmall
                    }
                }
                ComboBox {
                    objectName: "languageSelector"
                    model: ["简体中文", "English"]
                    currentIndex: settings.language === "zh_CN" ? 0 : 1
                    onActivated: (index) => settings.language = index === 0 ? "zh_CN" : "en"
                }
            }
        }

        // ---- General ----
        Card {
            Layout.fillWidth: true
            implicitHeight: generalCol.implicitHeight + padding * 2

            ColumnLayout {
                id: generalCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                spacing: 2

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Rectangle {
                        width: 34; height: 34; radius: 8
                        color: Theme.cardHover
                        IconImage {
                            anchors.centerIn: parent
                            source: Theme.icon("power"); size: 17; color: Theme.accentSoft
                        }
                    }

                    Column {
                        Layout.fillWidth: true
                        spacing: 1
                        Text {
                            text: qsTr("Start Stacer on login")
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fsBody
                            font.weight: Theme.weightMedium
                        }
                        Text {
                            text: qsTr("Launch automatically when you sign in")
                            color: Theme.textDim
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fsSmall
                        }
                    }

                    Toggle {
                        checked: settings.startOnLogin
                        onToggled: (v) => settings.startOnLogin = v
                    }
                }
            }
        }

        Card {
            Layout.fillWidth: true
            implicitHeight: trayRow.implicitHeight + padding * 2

            RowLayout {
                id: trayRow
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                spacing: 12
                Column {
                    Layout.fillWidth: true
                    spacing: 1
                    Text {
                        text: qsTr("Close to system tray")
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fsBody
                        font.weight: Theme.weightMedium
                    }
                    Text {
                        text: qsTr("Keep running when the window is closed")
                        color: Theme.textDim
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fsSmall
                    }
                }
                Toggle {
                    checked: settings.closeToTray
                    onToggled: (v) => settings.closeToTray = v
                }
            }
        }

        // ---- Resource alerts ----
        Card {
            Layout.fillWidth: true
            implicitHeight: alertCol.implicitHeight + padding * 2

            ColumnLayout {
                id: alertCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    Rectangle {
                        width: 34; height: 34; radius: 8
                        color: Theme.cardHover
                        IconImage {
                            anchors.centerIn: parent
                            source: Theme.icon("activity"); size: 17; color: Theme.accentSoft
                        }
                    }
                    Column {
                        Layout.fillWidth: true
                        spacing: 1
                        Text {
                            text: qsTr("Resource alerts")
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fsBody
                            font.weight: Theme.weightMedium
                        }
                        Text {
                            text: qsTr("Notify when usage crosses a limit")
                            color: Theme.textDim
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fsSmall
                        }
                    }
                    Toggle {
                        checked: system.alertsEnabled
                        onToggled: (v) => system.alertsEnabled = v
                    }
                }

                // thresholds
                Repeater {
                    model: [
                        { label: qsTr("CPU usage"),    key: "cpu" },
                        { label: qsTr("Memory usage"), key: "mem" },
                        { label: qsTr("Disk usage"),   key: "disk" }
                    ]
                    delegate: RowLayout {
                        required property var modelData
                        Layout.fillWidth: true
                        opacity: system.alertsEnabled ? 1 : 0.45
                        Text {
                            Layout.fillWidth: true
                            text: modelData.label
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fsBody
                        }
                        NumberStepper {
                            enabled: system.alertsEnabled
                            value: modelData.key === "cpu" ? system.cpuAlert
                                 : modelData.key === "mem" ? system.memAlert : system.diskAlert
                            onChanged: (v) => {
                                if (modelData.key === "cpu") system.cpuAlert = v
                                else if (modelData.key === "mem") system.memAlert = v
                                else system.diskAlert = v
                            }
                        }
                    }
                }
            }
        }

        // ---- Appearance ----
        Card {
            Layout.fillWidth: true
            implicitHeight: appearCol.implicitHeight + padding * 2

            ColumnLayout {
                id: appearCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    Column {
                        Layout.fillWidth: true
                        spacing: 1
                        Text {
                            text: qsTr("Theme")
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fsBody
                            font.weight: Theme.weightMedium
                        }
                        Text {
                            text: qsTr("PC Manager · dark")
                            color: Theme.textDim
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fsSmall
                        }
                    }
                    Logo { size: 26 }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    Text {
                        Layout.fillWidth: true
                        text: qsTr("Accent color")
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fsBody
                        font.weight: Theme.weightMedium
                    }
                    Rectangle {
                        width: 22; height: 22; radius: 6
                        color: Theme.accent
                    }
                    Text {
                        text: settings.accentHex
                        color: Theme.textDim
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fsBody
                    }
                }
            }
        }

        // ---- Storage ----
        Card {
            Layout.fillWidth: true
            implicitHeight: storageCol.implicitHeight + padding * 2

            ColumnLayout {
                id: storageCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                spacing: 2

                Text {
                    text: qsTr("Configuration")
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fsBody
                    font.weight: Theme.weightMedium
                }
                Text {
                    Layout.fillWidth: true
                    text: settings.configPath
                    color: Theme.textDim
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fsSmall
                    elide: Text.ElideMiddle
                }
            }
        }
    }
    }
}

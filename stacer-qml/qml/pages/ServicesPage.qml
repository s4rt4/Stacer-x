import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import Stacer

// systemd services backed by the `services` controller. Loaded lazily when
// the page first appears (the scan is expensive and runs off-thread).
Item {
    id: page

    onVisibleChanged: services.setActive(visible)
    Component.onCompleted: if (visible) services.setActive(true)

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.padCard
        spacing: Theme.gap

        // ---- Header ----
        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            Text {
                text: "Services"
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fsTitle
                font.weight: Theme.weightMedium
            }
            Item { Layout.fillWidth: true }
            Text {
                text: services.loading ? "Scanning…" : services.count + " services"
                color: Theme.textDim
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fsBody
            }
            SearchField {
                Layout.preferredWidth: 200
                placeholder: "Search services"
                onTextChanged: services.filter = text
            }
        }

        // ---- List card ----
        Card {
            Layout.fillWidth: true
            Layout.fillHeight: true
            padding: 8

            // Loading placeholder
            Column {
                anchors.centerIn: parent
                spacing: 10
                visible: services.loading && services.count === 0
                BusyIndicator { anchors.horizontalCenter: parent.horizontalCenter; running: parent.visible }
                Text {
                    text: "Scanning services…"
                    color: Theme.textDim
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fsBody
                }
            }

            ColumnLayout {
                anchors.fill: parent
                spacing: 0
                visible: services.count > 0

                // column headers
                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 8
                    Layout.rightMargin: 8
                    Layout.bottomMargin: 6
                    Layout.topMargin: 4
                    spacing: 12
                    Text {
                        text: "Service"; color: Theme.textDim
                        font.family: Theme.fontFamily; font.pixelSize: Theme.fsSmall
                        Layout.fillWidth: true
                    }
                    Text {
                        text: "Startup"; color: Theme.textDim
                        font.family: Theme.fontFamily; font.pixelSize: Theme.fsSmall
                        horizontalAlignment: Text.AlignHCenter; Layout.preferredWidth: 60
                    }
                    Text {
                        text: "Running"; color: Theme.textDim
                        font.family: Theme.fontFamily; font.pixelSize: Theme.fsSmall
                        horizontalAlignment: Text.AlignHCenter; Layout.preferredWidth: 60
                    }
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: Theme.border }

                ListView {
                    id: list
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    model: services
                    boundsBehavior: Flickable.StopAtBounds
                    ScrollBar.vertical: ScrollBar { }

                    delegate: Rectangle {
                        id: row
                        required property string name
                        required property string description
                        required property bool active
                        required property bool enabled

                        width: ListView.view.width
                        height: 50
                        radius: 6
                        // Instant hover (see ProcessesPage) — no trailing highlight.
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
                                    text: row.name
                                    color: Theme.text
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fsBody
                                    font.weight: Theme.weightMedium
                                    elide: Text.ElideRight
                                    width: parent.width
                                }
                                Text {
                                    text: row.description
                                    color: Theme.textDim
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fsSmall
                                    elide: Text.ElideRight
                                    width: parent.width
                                    visible: text.length > 0
                                }
                            }

                            Item {
                                Layout.preferredWidth: 60
                                Layout.fillHeight: true
                                Toggle {
                                    anchors.centerIn: parent
                                    checked: row.enabled
                                    onToggled: (v) => services.toggleEnabled(row.name, v)
                                }
                            }
                            Item {
                                Layout.preferredWidth: 60
                                Layout.fillHeight: true
                                Toggle {
                                    anchors.centerIn: parent
                                    checked: row.active
                                    onToggled: (v) => services.toggleActive(row.name, v)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

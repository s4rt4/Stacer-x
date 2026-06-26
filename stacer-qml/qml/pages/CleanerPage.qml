import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import Stacer

// System cleaner backed by the `cleaner` controller. Scans junk categories
// (sizes off-thread), lets the user pick categories, then cleans.
Item {
    id: page

    onVisibleChanged: cleaner.setActive(visible)
    Component.onCompleted: if (visible) cleaner.setActive(true)

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.padCard
        spacing: Theme.gap

        // ---- Header ----
        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "System cleaner"
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fsTitle
                font.weight: Theme.weightMedium
            }
            Item { Layout.fillWidth: true }
            BusyIndicator {
                running: cleaner.busy
                visible: cleaner.busy
                implicitWidth: 20; implicitHeight: 20
            }
            Text {
                text: cleaner.busy ? "Working…" : "Rescan"
                color: cleaner.busy ? Theme.textDim : Theme.accentSoft
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fsBody
                TapHandler { enabled: !cleaner.busy; onTapped: cleaner.scan() }
                HoverHandler { enabled: !cleaner.busy; cursorShape: Qt.PointingHandCursor }
            }
        }

        // ---- Categories ----
        Card {
            Layout.fillWidth: true
            // Rectangle doesn't size to children — derive height from content.
            implicitHeight: catCol.implicitHeight + padding * 2

            ColumnLayout {
                id: catCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                spacing: 4

                Repeater {
                    model: cleaner
                    delegate: Column {
                        id: catRoot
                        required property int index
                        required property string key
                        required property string label
                        required property string icon
                        required property string sizeText
                        required property bool selected

                        Layout.fillWidth: true
                        spacing: 0

                        property bool expanded: false
                        property var detailItems: []
                        property bool detailLoading: false

                        Connections {
                            target: cleaner
                            function onDetailsReady(k, items) {
                                if (k === catRoot.key) {
                                    catRoot.detailItems = items
                                    catRoot.detailLoading = false
                                }
                            }
                        }

                        function toggleDetails() {
                            expanded = !expanded
                            if (expanded && detailItems.length === 0) {
                                detailLoading = true
                                cleaner.requestDetails(key)
                            }
                        }

                        // ---- header row ----
                        Rectangle {
                            width: parent.width
                            height: 52
                            radius: 8
                            color: headerHover.hovered ? Theme.cardHover : "transparent"

                            HoverHandler { id: headerHover }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                spacing: 12

                                Rectangle {
                                    width: 32; height: 32; radius: 8
                                    color: Theme.card
                                    IconImage {
                                        anchors.centerIn: parent
                                        source: Theme.icon(catRoot.icon)
                                        size: 17
                                        color: catRoot.selected ? Theme.accentSoft : Theme.textDim
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: catRoot.label
                                    color: Theme.text
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fsBody
                                    font.weight: Theme.weightMedium
                                }

                                // Details toggle
                                Row {
                                    spacing: 4
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: catRoot.expanded ? "Hide" : "Details"
                                        color: detailHover.hovered ? Theme.accentSoft : Theme.textDim
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fsSmall
                                    }
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "›"
                                        color: detailHover.hovered ? Theme.accentSoft : Theme.textDim
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fsBody
                                        rotation: catRoot.expanded ? 90 : 0
                                        Behavior on rotation { NumberAnimation { duration: Theme.animFast } }
                                    }
                                    HoverHandler { id: detailHover; cursorShape: Qt.PointingHandCursor }
                                    TapHandler { onTapped: catRoot.toggleDetails() }
                                }

                                Text {
                                    text: catRoot.sizeText
                                    color: Theme.textDim
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fsBody
                                }

                                Toggle {
                                    checked: catRoot.selected
                                    onToggled: (v) => cleaner.setSelected(catRoot.index, v)
                                }
                            }
                        }

                        // ---- expandable detail list ----
                        Rectangle {
                            width: parent.width
                            clip: true
                            color: "transparent"
                            height: catRoot.expanded
                                    ? Math.min((catRoot.detailLoading ? 1 : Math.max(catRoot.detailItems.length, 1)) * 26 + 12, 200)
                                    : 0
                            Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

                            // loading / empty
                            Text {
                                anchors.left: parent.left
                                anchors.leftMargin: 52
                                anchors.top: parent.top
                                anchors.topMargin: 6
                                visible: catRoot.detailLoading || catRoot.detailItems.length === 0
                                text: catRoot.detailLoading ? "Scanning…" : "Nothing to remove"
                                color: Theme.textDim
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fsSmall
                            }

                            ListView {
                                anchors.fill: parent
                                anchors.leftMargin: 52
                                anchors.rightMargin: 8
                                anchors.topMargin: 4
                                anchors.bottomMargin: 8
                                clip: true
                                visible: !catRoot.detailLoading && catRoot.detailItems.length > 0
                                model: catRoot.detailItems
                                boundsBehavior: Flickable.StopAtBounds
                                ScrollBar.vertical: ScrollBar { }

                                delegate: Row {
                                    required property var modelData
                                    width: ListView.view.width
                                    height: 26
                                    Text {
                                        width: parent.width - sz.width - 10
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData.name
                                        color: Theme.textDim
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fsSmall
                                        elide: Text.ElideMiddle
                                    }
                                    Text {
                                        id: sz
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData.sizeText
                                        color: Theme.textDim
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fsSmall
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // ---- Clean action ----
        AccentButton {
            Layout.fillWidth: true
            text: "Clean  •  " + cleaner.totalSelectedText
            busy: cleaner.busy
            busyText: "Cleaning…"
            onClicked: cleaner.clean()
        }

        Item { Layout.fillHeight: true }
    }
}

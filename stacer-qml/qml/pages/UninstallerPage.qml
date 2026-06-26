import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import Stacer

// Installed packages backed by the `uninstaller` controller. Select packages
// and uninstall them via the detected package manager (elevated).
Item {
    id: page

    onVisibleChanged: uninstaller.setActive(visible)
    Component.onCompleted: if (visible) uninstaller.setActive(true)

    // Leftover config/cache folders for the current selection (preview).
    property var leftovers: []
    function refreshLeftovers() {
        if (uninstaller.removeConfig)
            uninstaller.requestLeftovers()
        else
            page.leftovers = []
    }
    Connections {
        target: uninstaller
        function onLeftoversReady(items) { page.leftovers = items }
        function onSelectionChanged() { page.refreshLeftovers() }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.padCard
        spacing: Theme.gap

        // ---- Header ----
        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            Text {
                text: "Uninstaller"
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fsTitle
                font.weight: Theme.weightMedium
            }
            Item { Layout.fillWidth: true }
            Text {
                text: "Autoremove unused deps"
                color: autoHover.hovered && !uninstaller.busy ? Theme.accentSoft : Theme.textDim
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fsBody
                HoverHandler { id: autoHover; enabled: !uninstaller.busy; cursorShape: Qt.PointingHandCursor }
                TapHandler { enabled: !uninstaller.busy; onTapped: uninstaller.autoremove() }
            }
            Rectangle { width: 1; height: 16; color: Theme.border }
            Text {
                text: uninstaller.busy ? "Working…"
                                       : (uninstaller.count + " of " + uninstaller.total + " · " + uninstaller.manager)
                color: Theme.textDim
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fsBody
            }
            SearchField {
                Layout.preferredWidth: 200
                placeholder: "Search packages"
                onTextChanged: uninstaller.filter = text
            }
        }

        // ---- List ----
        Card {
            Layout.fillWidth: true
            Layout.fillHeight: true
            padding: 8

            Column {
                anchors.centerIn: parent
                spacing: 10
                visible: uninstaller.busy && uninstaller.count === 0
                BusyIndicator { anchors.horizontalCenter: parent.horizontalCenter; running: parent.visible }
                Text {
                    text: "Loading packages…"
                    color: Theme.textDim
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fsBody
                }
            }

            ListView {
                id: list
                anchors.fill: parent
                clip: true
                model: uninstaller
                visible: uninstaller.count > 0
                boundsBehavior: Flickable.StopAtBounds
                ScrollBar.vertical: ScrollBar { }

                delegate: Rectangle {
                    required property string name
                    required property bool selected

                    width: ListView.view.width
                    height: 38
                    radius: 6
                    color: selected ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.12)
                                     : (hover.hovered ? Theme.cardHover : "transparent")

                    HoverHandler { id: hover }
                    TapHandler { onTapped: uninstaller.toggle(name) }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 12

                        // check box
                        Rectangle {
                            width: 18; height: 18; radius: 5
                            color: selected ? Theme.accent : "transparent"
                            border.width: selected ? 0 : 1.5
                            border.color: Theme.textDim
                            Text {
                                anchors.centerIn: parent
                                text: "✓"
                                visible: selected
                                color: Theme.accentText
                                font.pixelSize: 12
                                font.weight: Theme.weightMedium
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: name
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fsBody
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }

        // ---- Leftover preview ----
        Card {
            Layout.fillWidth: true
            visible: uninstaller.removeConfig && uninstaller.selectedCount > 0
            implicitHeight: visible ? leftCol.implicitHeight + padding * 2 : 0

            ColumnLayout {
                id: leftCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                spacing: 4

                Text {
                    text: page.leftovers.length > 0
                          ? "Will also remove " + page.leftovers.length + " config/cache folder(s):"
                          : "No matching config/cache folders found"
                    color: Theme.textDim
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fsSmall
                }
                Repeater {
                    model: page.leftovers
                    delegate: RowLayout {
                        required property var modelData
                        Layout.fillWidth: true
                        Text {
                            Layout.fillWidth: true
                            text: modelData.path
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fsSmall
                            elide: Text.ElideMiddle
                        }
                        Text {
                            text: modelData.sizeText
                            color: Theme.textDim
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fsSmall
                        }
                    }
                }
            }
        }

        // ---- Action ----
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.gap

            Toggle {
                checked: uninstaller.removeConfig
                onToggled: (v) => { uninstaller.removeConfig = v; page.refreshLeftovers() }
            }
            Text {
                text: "Also remove user config & cache"
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fsBody
            }
            Item { Layout.fillWidth: true }
            Text {
                visible: uninstaller.selectedCount > 0
                text: uninstaller.selectedCount + " selected · clear"
                color: clearHover.hovered ? Theme.accentSoft : Theme.textDim
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fsBody
                HoverHandler { id: clearHover; cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: uninstaller.clearSelection() }
            }
            AccentButton {
                text: "Uninstall" + (uninstaller.selectedCount > 0 ? "  (" + uninstaller.selectedCount + ")" : "")
                busy: uninstaller.busy
                busyText: "Uninstalling…"
                opacity: uninstaller.selectedCount > 0 ? 1 : 0.5
                onClicked: if (uninstaller.selectedCount > 0) uninstaller.removeSelected()
            }
        }
    }
}

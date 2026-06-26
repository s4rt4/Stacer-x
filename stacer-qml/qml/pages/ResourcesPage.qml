import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import Stacer

// Live CPU / GPU / memory / disk / network charts backed by `resmon`.
// (Not "resources" — that name shadows Item.resources in QML.)
Item {
    id: page

    onVisibleChanged: resmon.setActive(visible)
    Component.onCompleted: if (visible) resmon.setActive(true)

    readonly property int chartHeight: 132

    ScrollView {
        anchors.fill: parent
        anchors.margins: Theme.padCard
        contentWidth: availableWidth
        clip: true
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

        ColumnLayout {
            width: page.width - Theme.padCard * 2
            spacing: Theme.gap

            ResourceChart {
                Layout.fillWidth: true
                Layout.preferredHeight: page.chartHeight
                iconSource: Theme.icon("cpu")
                title: "CPU"
                value: system.cpuPercent + "%"
                values: system.cpuHistory
                maxValue: 100
                accent: Theme.accent
            }

            ResourceChart {
                Layout.fillWidth: true
                Layout.preferredHeight: visible ? page.chartHeight : 0
                visible: resmon.gpuAvailable
                iconSource: Theme.icon("gpu")
                title: "GPU"
                value: resmon.gpuPercent + "%"
                values: resmon.gpuHistory
                maxValue: 100
                accent: Theme.accentSoft
            }

            ResourceChart {
                Layout.fillWidth: true
                Layout.preferredHeight: visible ? page.chartHeight : 0
                visible: resmon.nvAvailable
                iconSource: Theme.icon("microchip")
                title: "NVIDIA GPU"
                value: resmon.nvPercent + "%   " + resmon.nvText
                values: resmon.nvHistory
                maxValue: 100
                accent: "#76b900"   // NVIDIA green
            }

            ResourceChart {
                Layout.fillWidth: true
                Layout.preferredHeight: page.chartHeight
                iconSource: Theme.icon("memory-stick")
                title: "Memory"
                value: resmon.memText
                values: resmon.memHistory
                maxValue: 100
                accent: Theme.accentSoft
            }

            ResourceChart {
                Layout.fillWidth: true
                Layout.preferredHeight: page.chartHeight
                iconSource: Theme.icon("hard-drive")
                title: "Disk"
                value: resmon.diskText
                values: resmon.diskHistory
                maxValue: 0
                accent: "#c9a0ff"
            }

            ResourceChart {
                Layout.fillWidth: true
                Layout.preferredHeight: page.chartHeight
                iconSource: Theme.icon("activity")
                title: "Network"
                value: "↓ " + resmon.downText + "    ↑ " + resmon.upText
                values: resmon.downHistory
                maxValue: 0
                accent: Theme.warn
            }
        }
    }
}

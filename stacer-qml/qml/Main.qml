import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import Stacer

ApplicationWindow {
    id: window
    visible: true
    // Fixed size — non-resizable by design (min == max).
    width: 720
    height: 700
    minimumWidth: width
    maximumWidth: width
    minimumHeight: height
    maximumHeight: height
    title: "Stacer-X"
    color: Theme.bg
    flags: Qt.Window | Qt.FramelessWindowHint

    // Nav definition — order mirrors mockup-stacer.html.
    readonly property var navModel: [
        { icon: "house",                  label: "Dashboard" },
        { icon: "eraser",                 label: "Cleaner" },
        { icon: "server",                 label: "Services" },
        { icon: "list",                   label: "Processes" },
        { icon: "power",                  label: "Startup" },
        { icon: "package",                label: "Uninstaller" },
        { icon: "wrench",                 label: "Hosts" },
        { icon: "chart-no-axes-combined", label: "Resources" },
        { icon: "hard-drive",             label: "Disk" },
        { icon: "settings",               label: "Settings", bottom: true },
        { icon: "info",                   label: "About",    bottom: true }
    ]
    property int currentIndex: 0

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        TitleBar {
            Layout.fillWidth: true
            win: window
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            NavRail {
                Layout.fillHeight: true
                model: window.navModel
                currentIndex: window.currentIndex
                onNavigate: (index) => window.currentIndex = index
            }

            // Content area — page swapped by nav.
            StackLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: window.currentIndex

                DashboardPage {}                          // 0 Dashboard
                CleanerPage {}                            // 1 Cleaner
                ServicesPage {}                           // 2 Services
                ProcessesPage {}                          // 3 Processes
                StartupPage {}                            // 4 Startup
                UninstallerPage {}                        // 5 Uninstaller
                HostsPage {}                              // 6 Hosts
                ResourcesPage {}                          // 7 Resources
                DiskPage {}                               // 8 Disk
                SettingsPage {}                           // 9 Settings
                AboutPage {}                              // 10 About
            }
        }
    }
}

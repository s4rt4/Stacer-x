pragma Singleton
import QtQuick

// Design tokens — single source of truth, ported from ui-guideline-stacer.md §2-4
// and mockup-stacer.html :root. Keep guideline ↔ mockup ↔ Theme.qml in sync.
QtObject {
    // ---- Color ----
    readonly property color bg:         "#1c1d27"
    readonly property color sidebar:    "#191a22"
    readonly property color card:       "#2a2c39"
    readonly property color cardHover:  "#313342"
    readonly property color accent:     "#5cc4ef"
    readonly property color accentText: "#0c3a50"
    readonly property color accentSoft: "#6fcdf2"
    readonly property color text:       "#f0f1f4"
    readonly property color textDim:    "#9a9ca8"
    readonly property color border:     Qt.rgba(1, 1, 1, 0.06)
    readonly property color warn:       "#f0c060"
    readonly property color good:       "#5fd08a"
    readonly property color danger:     "#f0726a"

    // ---- Shape ----
    readonly property int radiusWindow: 12
    readonly property int radiusCard:   10
    readonly property int radiusBtn:    8
    readonly property int radiusNav:    9

    // ---- Spacing ----
    readonly property int gap:        12
    readonly property int padCard:    16
    readonly property int sidebarW:   58

    // ---- Typography ----
    readonly property string fontFamily: "Inter"
    readonly property int fsTitle:  14   // card title
    readonly property int fsBody:   13   // body / status
    readonly property int fsSmall:  11   // small label / nav label
    readonly property int fsMetric: 18   // metric number
    readonly property int weightRegular: Font.Normal
    readonly property int weightMedium:  Font.Medium

    // ---- Motion ----
    readonly property int animFast: 120

    // Full-color brand logo (rendered as-is, not recolored).
    readonly property url logo: Qt.resolvedUrl("stacer-logo.svg")

    // Resolve an icon SVG (Lucide set) by name, relative to this singleton.
    function icon(name) {
        return Qt.resolvedUrl("icons/" + name + ".svg")
    }
}

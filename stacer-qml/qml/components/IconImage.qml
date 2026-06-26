import QtQuick
import Qt5Compat.GraphicalEffects
import Stacer

// SVG icon rendered crisp at HiDPI, recolored to `color` via ColorOverlay.
// One file per icon; the tint follows state (no per-state icon files).
Item {
    id: root

    property url source
    property color color: Theme.textDim
    property int size: 19

    implicitWidth: size
    implicitHeight: size

    Image {
        id: img
        anchors.fill: parent
        source: root.source
        sourceSize.width: root.size * 2
        sourceSize.height: root.size * 2
        fillMode: Image.PreserveAspectFit
        smooth: true
        visible: false
    }

    ColorOverlay {
        anchors.fill: img
        source: img
        color: root.color

        Behavior on color { ColorAnimation { duration: Theme.animFast } }
    }
}

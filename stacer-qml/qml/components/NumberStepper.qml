import QtQuick
import Stacer

// −  value  +  stepper for bounded integer values.
Row {
    id: root

    property int value: 0
    property int step: 5
    property int from: 0
    property int to: 100
    property string suffix: "%"
    property bool enabled: true
    signal changed(int value)

    spacing: 8

    function clamp(v) { return Math.max(from, Math.min(to, v)) }

    component StepBtn: Rectangle {
        property string glyph
        signal tapped
        width: 26; height: 26; radius: 6
        opacity: root.enabled ? 1 : 0.4
        color: hov.hovered && root.enabled ? Theme.cardHover : Theme.card
        Behavior on color { ColorAnimation { duration: Theme.animFast } }
        Text {
            anchors.centerIn: parent
            text: parent.glyph
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fsTitle
        }
        HoverHandler { id: hov; cursorShape: Qt.PointingHandCursor }
        TapHandler { enabled: root.enabled; onTapped: parent.tapped() }
    }

    StepBtn {
        glyph: "−"
        anchors.verticalCenter: parent.verticalCenter
        onTapped: root.changed(root.clamp(root.value - root.step))
    }
    Text {
        anchors.verticalCenter: parent.verticalCenter
        width: 44
        horizontalAlignment: Text.AlignHCenter
        text: root.value <= 0 ? "Off" : (root.value + root.suffix)
        color: root.enabled ? Theme.text : Theme.textDim
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fsBody
        font.weight: Theme.weightMedium
    }
    StepBtn {
        glyph: "+"
        anchors.verticalCenter: parent.verticalCenter
        onTapped: root.changed(root.clamp(root.value + root.step))
    }
}

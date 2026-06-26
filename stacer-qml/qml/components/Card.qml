import QtQuick
import Stacer

// Rounded card on dark bg. Default content padding via `padding`.
Rectangle {
    id: root

    default property alias content: inner.data
    property int padding: Theme.padCard
    property bool hoverable: false

    color: (hoverable && hover.hovered) ? Theme.cardHover : Theme.card
    radius: Theme.radiusCard

    Behavior on color { ColorAnimation { duration: Theme.animFast } }

    HoverHandler { id: hover }

    Item {
        id: inner
        anchors.fill: parent
        anchors.margins: root.padding
    }
}

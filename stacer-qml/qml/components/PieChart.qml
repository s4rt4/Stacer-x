import QtQuick
import Stacer

// Donut chart. `slices` is an array of { value, color }.
Canvas {
    id: canvas

    property var slices: []
    property real hole: 0.62
    property color holeColor: Theme.card

    onSlicesChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onHoleColorChanged: requestPaint()

    onPaint: {
        var ctx = getContext("2d")
        ctx.reset()

        var s = slices || []
        var n = s.length
        if (n === 0)
            return

        var total = 0
        for (var i = 0; i < n; ++i)
            total += s[i].value
        if (total <= 0)
            return

        var cx = width / 2, cy = height / 2
        var r = Math.min(cx, cy) - 2
        var a = -Math.PI / 2

        for (var j = 0; j < n; ++j) {
            var frac = s[j].value / total
            var a2 = a + frac * 2 * Math.PI
            ctx.beginPath()
            ctx.moveTo(cx, cy)
            ctx.arc(cx, cy, r, a, a2)
            ctx.closePath()
            ctx.fillStyle = s[j].color
            ctx.fill()
            // thin separator
            ctx.lineWidth = 2
            ctx.strokeStyle = holeColor
            ctx.stroke()
            a = a2
        }

        if (hole > 0) {
            ctx.beginPath()
            ctx.arc(cx, cy, r * hole, 0, 2 * Math.PI)
            ctx.fillStyle = holeColor
            ctx.fill()
        }
    }
}

import QtQuick
import Stacer

// Lightweight filled line chart drawn on a Canvas — no external chart module.
// `values` is an array of numbers; `maxValue` <= 0 means auto-scale.
Canvas {
    id: canvas

    property var values: []
    property real maxValue: 0
    property color lineColor: Theme.accent
    property real fillAlpha: 0.16

    onValuesChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        var ctx = getContext("2d")
        ctx.reset()

        var vals = values || []
        var n = vals.length
        if (n < 2)
            return

        var mx = maxValue
        if (mx <= 0) {
            mx = 1
            for (var i = 0; i < n; ++i)
                mx = Math.max(mx, vals[i])
        }

        var w = width, h = height
        var dx = w / (n - 1)
        function yOf(v) {
            var c = Math.max(0, Math.min(v, mx))
            return h - (c / mx) * (h - 2) - 1
        }

        // filled area
        ctx.beginPath()
        ctx.moveTo(0, h)
        for (var j = 0; j < n; ++j)
            ctx.lineTo(j * dx, yOf(vals[j]))
        ctx.lineTo(w, h)
        ctx.closePath()
        ctx.fillStyle = Qt.rgba(lineColor.r, lineColor.g, lineColor.b, fillAlpha)
        ctx.fill()

        // line
        ctx.beginPath()
        for (var k = 0; k < n; ++k) {
            var px = k * dx, py = yOf(vals[k])
            if (k === 0)
                ctx.moveTo(px, py)
            else
                ctx.lineTo(px, py)
        }
        ctx.lineWidth = 2
        ctx.lineJoin = "round"
        ctx.strokeStyle = lineColor
        ctx.stroke()
    }
}

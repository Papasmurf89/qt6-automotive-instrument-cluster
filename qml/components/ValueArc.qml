// Coloured arc from the gauge start to the current needle position.
// Instantiated by Gauge.qml through a Loader (optional QtQuick.Shapes).
import QtQuick
import QtQuick.Shapes
import Dashboard

Shape {
    id: arc

    required property Gauge gauge

    // Geometry renderer: a thin stroked arc is a few hundred vertices; works
    // with both the RHI (GPU) and the software scene graph backend.
    preferredRendererType: Shape.GeometryRenderer
    asynchronous: false

    ShapePath {
        strokeColor: arc.gauge.arcColor
        strokeWidth: arc.gauge.ringWidth
        fillColor: "transparent"
        capStyle: ShapePath.FlatCap

        PathAngleArc {
            centerX: arc.gauge.width / 2
            centerY: arc.gauge.height / 2
            radiusX: arc.gauge.ringRadius
            radiusY: arc.gauge.ringRadius
            startAngle: arc.gauge.startAngle - 90
            sweepAngle: Math.max(0.01, arc.gauge.needleAngle - arc.gauge.startAngle)
        }
    }
}

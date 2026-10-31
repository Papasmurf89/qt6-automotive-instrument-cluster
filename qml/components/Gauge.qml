// Generic round gauge: static face (Canvas, painted once per size/theme
// change), optional live value arc (Shapes), rotating needle (Rectangle).
// Put readouts inside it as children - they are centred on the dial.
pragma ComponentBehavior: Bound
import QtQuick
import Dashboard

Item {
    id: root

    // ---- Public API --------------------------------------------------------
    property real value: 0
    property real minValue: 0
    property real maxValue: 100
    property real startAngle: -135      // degrees, 0 = 12 o'clock, clockwise
    property real sweepAngle: 270
    property real majorStep: 20
    property int minorDivisions: 4      // minor ticks per major interval
    property real labelDivisor: 1       // e.g. 1000 for a tachometer
    property bool redlineEnabled: false
    property real redlineFrom: maxValue
    property bool showValueArc: true
    property color arcColor: Theme.accent
    property color needleColor: Theme.needle
    property real needleVelocity: 200   // value units per second (needle smoothing)
    // Startup sweep: 0..1 forces the needle to that fraction, -1 = live value.
    property real sweepFraction: -1
    default property alias content: centre.data

    // ---- Derived -----------------------------------------------------------
    readonly property real diameter: Math.min(width, height)
    readonly property real dialRadius: diameter / 2
    readonly property real span: Math.max(1e-6, maxValue - minValue)
    readonly property bool sweeping: sweepFraction >= 0
    readonly property real targetValue: sweeping ? minValue + sweepFraction * span
                                                 : Math.max(minValue, Math.min(maxValue, value))
    property real shownValue: targetValue
    Behavior on shownValue {
        enabled: !root.sweeping
        SmoothedAnimation { velocity: root.needleVelocity }
    }
    readonly property real needleAngle: angleFor(shownValue)
    readonly property real ringRadius: dialRadius * 0.93
    readonly property real ringWidth: Math.max(3, dialRadius * 0.045)

    function angleFor(v: real): real {
        return startAngle + (v - minValue) / span * sweepAngle
    }

    implicitWidth: Theme.px(300)
    implicitHeight: Theme.px(300)

    // Dial background (opaque, no gradient: cheap on software rendering).
    Rectangle {
        anchors.centerIn: parent
        width: root.diameter
        height: root.diameter
        radius: width / 2
        color: Theme.gaugeFace
        border.color: Theme.border
        border.width: Math.max(1, Theme.px(2))
    }

    // Static face: track ring, redline band, ticks. Repainted only when the
    // geometry, scale or theme changes - never per frame.
    Canvas {
        id: face
        anchors.centerIn: parent
        width: root.diameter
        height: root.diameter
        readonly property string paintKey: [root.diameter, root.minValue, root.maxValue, root.majorStep,
                                            root.redlineFrom, root.redlineEnabled, Theme.night].join("|")
        onPaintKeyChanged: requestPaint()

        function rad(deg: real): real { return (deg - 90) * Math.PI / 180 }

        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            if (width <= 0)
                return
            const cx = width / 2
            const cy = height / 2
            const r = width / 2

            // Track ring
            ctx.lineWidth = root.ringWidth
            ctx.lineCap = "butt"
            ctx.strokeStyle = String(Theme.gaugeTrack)
            ctx.beginPath()
            ctx.arc(cx, cy, root.ringRadius, rad(root.startAngle), rad(root.startAngle + root.sweepAngle), false)
            ctx.stroke()

            // Redline band on the ring
            if (root.redlineEnabled) {
                ctx.strokeStyle = String(Theme.redline)
                ctx.beginPath()
                ctx.arc(cx, cy, root.ringRadius, rad(root.angleFor(root.redlineFrom)),
                        rad(root.startAngle + root.sweepAngle), false)
                ctx.stroke()
            }

            // Ticks
            const minorStep = root.majorStep / Math.max(1, root.minorDivisions)
            const count = Math.round(root.span / minorStep)
            const outer = r * 0.86
            for (let i = 0; i <= count; ++i) {
                const v = root.minValue + i * minorStep
                const major = (i % root.minorDivisions) === 0
                const a = rad(root.angleFor(v))
                const len = major ? r * 0.10 : r * 0.05
                const red = root.redlineEnabled && v >= root.redlineFrom - 1e-6
                ctx.lineWidth = major ? Math.max(2, r * 0.022) : Math.max(1, r * 0.011)
                ctx.strokeStyle = String(red ? Theme.redline : (major ? Theme.tickMajor : Theme.tickMinor))
                ctx.beginPath()
                ctx.moveTo(cx + Math.cos(a) * outer, cy + Math.sin(a) * outer)
                ctx.lineTo(cx + Math.cos(a) * (outer - len), cy + Math.sin(a) * (outer - len))
                ctx.stroke()
            }
        }
    }

    // Numeric labels: real Text items (crisp glyphs, cached by the scene graph).
    Repeater {
        model: Math.floor(root.span / root.majorStep + 1e-6) + 1
        delegate: Text {
            required property int index
            readonly property real labelValue: root.minValue + index * root.majorStep
            readonly property real angleRad: root.angleFor(labelValue) * Math.PI / 180
            readonly property real labelRadius: root.dialRadius * 0.64
            x: root.width / 2 + Math.sin(angleRad) * labelRadius - width / 2
            y: root.height / 2 - Math.cos(angleRad) * labelRadius - height / 2
            text: Math.round(labelValue / root.labelDivisor)
            color: root.redlineEnabled && labelValue >= root.redlineFrom ? Theme.redline : Theme.textPrimary
            font.family: Theme.fontFamily
            font.pixelSize: Math.max(14, Math.round(root.dialRadius * 0.12))
            font.bold: true
        }
    }

    // Live value arc. Loaded dynamically so the gauge still works (without the
    // arc) if the QtQuick.Shapes module is missing on the target image.
    Loader {
        id: arcLoader
        anchors.fill: parent
        active: root.showValueArc
        asynchronous: false
        Component.onCompleted: setSource(Qt.resolvedUrl("ValueArc.qml"), { gauge: root })
        onStatusChanged: if (status === Loader.Error)
                             console.warn("Gauge: value arc unavailable (QtQuick.Shapes missing?)")
    }

    // Centre content slot (readouts)
    Item {
        id: centre
        anchors.centerIn: parent
        width: root.diameter * 0.62
        height: root.diameter * 0.62
    }

    Needle {
        anchors.fill: parent
        angle: root.needleAngle
        length: root.dialRadius * 0.88
        innerRadius: root.dialRadius * 0.46
        thickness: Math.max(4, root.dialRadius * 0.045)
        color: root.needleColor
    }
}

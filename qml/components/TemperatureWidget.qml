// TemperatureWidget - reusable, self-contained thermometer display.
//
// All temperature inputs (value, minValue, maxValue, thresholds) are in
// degrees CELSIUS, the native unit of TemperatureProvider/VehicleData.
// `unit` only selects how numbers are DISPLAYED ("°C" or "°F"), so the zone
// logic never depends on the display unit.
//
// Zones:  cold      value <  coldThreshold          (blue)
//         normal    coldThreshold <= value < warning (green)
//         warning   warning <= value < critical      (amber)
//         critical  value >= criticalThreshold       (red, readout pulses)
//
// Example:
//     TemperatureWidget {
//         label: "BOARD"
//         value: TemperatureProvider.temperature
//         valid: TemperatureProvider.valid
//         minValue: 0; maxValue: 100
//         warningThreshold: 60; criticalThreshold: 72
//         unit: Theme.temperatureUnit
//     }
pragma ComponentBehavior: Bound
import QtQuick
import Dashboard

Item {
    id: root

    // ---- Public API ------------------------------------------------------
    property real value: 0
    property real minValue: -20
    property real maxValue: 120
    property real coldThreshold: minValue      // = minValue disables the cold zone
    property real warningThreshold: 90
    property real criticalThreshold: 105
    property string unit: "°C"                 // display unit: "°C" or "°F"
    property string label: "TEMP"
    property bool valid: true                  // false -> shows "--" (sensor fault/stale)
    property int decimals: 0
    property int animationDuration: 700        // ms, value smoothing

    // ---- Read-only state -------------------------------------------------
    enum Zone { Cold, Normal, Warning, Critical }
    readonly property int zone: value >= criticalThreshold ? TemperatureWidget.Zone.Critical
                              : value >= warningThreshold ? TemperatureWidget.Zone.Warning
                              : value < coldThreshold ? TemperatureWidget.Zone.Cold
                              : TemperatureWidget.Zone.Normal
    readonly property color zoneColor: !valid ? Theme.textDim
                                     : zone === TemperatureWidget.Zone.Critical ? Theme.critical
                                     : zone === TemperatureWidget.Zone.Warning ? Theme.warning
                                     : zone === TemperatureWidget.Zone.Cold ? Theme.cold
                                     : Theme.ok

    // Smoothly animated copy of `value` (drives both the readout and the bar).
    property real animatedValue: value
    Behavior on animatedValue {
        SmoothedAnimation { duration: root.animationDuration; velocity: -1 }
    }

    function toDisplay(celsius: real): real {
        return unit === "°F" ? celsius * 9 / 5 + 32 : celsius
    }
    function fraction(celsius: real): real {
        return Math.max(0, Math.min(1, (celsius - minValue) / Math.max(1e-6, maxValue - minValue)))
    }

    implicitWidth: Theme.px(88)
    implicitHeight: Theme.px(300)

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: Theme.surface
        border.color: Theme.border
        border.width: 1
    }

    Text {
        id: labelText
        anchors.top: parent.top
        anchors.topMargin: Theme.px(6)
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width - Theme.px(6)
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
        text: root.label
        color: Theme.textSecondary
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSmall
        font.letterSpacing: 1
    }

    Row {
        id: readout
        anchors.top: labelText.bottom
        anchors.horizontalCenter: parent.horizontalCenter

        Text {
            id: readoutValue
            text: root.valid ? root.toDisplay(root.animatedValue).toFixed(root.decimals) : "--"
            color: root.zoneColor
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontLarge
            font.bold: true

            // Pulse only while critical; stopped animations cost nothing.
            SequentialAnimation on opacity {
                running: root.valid && root.zone === TemperatureWidget.Zone.Critical && root.visible
                loops: Animation.Infinite
                alwaysRunToEnd: true
                NumberAnimation { to: 0.25; duration: 450 }
                NumberAnimation { to: 1.0; duration: 450 }
            }
        }
        Text {
            anchors.baseline: readoutValue.baseline
            text: root.unit
            color: Theme.textSecondary
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSmall
        }
    }

    // ---- Thermometer ------------------------------------------------------
    Item {
        id: gaugeArea
        anchors.top: readout.bottom
        anchors.topMargin: Theme.px(8)
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Theme.px(8)
        anchors.left: parent.left
        anchors.right: parent.right

        readonly property real bulbSize: Theme.px(24)
        readonly property real tubeWidth: Theme.px(12)
        readonly property real tubeX: Math.round(width * 0.36 - tubeWidth / 2)
        readonly property real tubeTop: Theme.px(6)
        readonly property real tubeBottom: height - bulbSize * 0.8
        readonly property real tubeHeight: Math.max(10, tubeBottom - tubeTop)

        function yFor(celsius: real): real {
            return tubeBottom - root.fraction(celsius) * tubeHeight
        }

        // Tube track
        Rectangle {
            id: tube
            x: gaugeArea.tubeX
            y: gaugeArea.tubeTop
            width: gaugeArea.tubeWidth
            height: gaugeArea.tubeHeight + gaugeArea.bulbSize * 0.4
            radius: width / 2
            color: Theme.gaugeTrack
        }

        // Fill level
        Rectangle {
            x: gaugeArea.tubeX + Theme.px(3)
            width: gaugeArea.tubeWidth - Theme.px(6)
            y: gaugeArea.yFor(root.animatedValue)
            height: gaugeArea.tubeBottom - y + gaugeArea.bulbSize * 0.4
            radius: width / 2
            visible: root.valid
            color: root.zoneColor
            Behavior on color { ColorAnimation { duration: 300 } }
        }

        // Bulb
        Rectangle {
            x: gaugeArea.tubeX + gaugeArea.tubeWidth / 2 - width / 2
            y: gaugeArea.height - height
            width: gaugeArea.bulbSize
            height: gaugeArea.bulbSize
            radius: width / 2
            color: root.zoneColor
            border.color: Theme.gaugeTrack
            border.width: Theme.px(3)
            Behavior on color { ColorAnimation { duration: 300 } }
        }

        // Zone strip next to the tube: cold / normal / warning / critical
        Repeater {
            model: [
                { from: root.minValue, to: root.coldThreshold, color: Theme.cold },
                { from: root.coldThreshold, to: root.warningThreshold, color: Theme.ok },
                { from: root.warningThreshold, to: root.criticalThreshold, color: Theme.warning },
                { from: root.criticalThreshold, to: root.maxValue, color: Theme.critical }
            ]
            delegate: Rectangle {
                required property var modelData
                x: gaugeArea.tubeX + gaugeArea.tubeWidth + Theme.px(4)
                width: Theme.px(4)
                y: gaugeArea.yFor(modelData.to)
                height: Math.max(0, gaugeArea.yFor(modelData.from) - y)
                color: modelData.color
                opacity: 0.85
            }
        }

        // Scale labels: max, warning threshold, min
        Repeater {
            model: [root.maxValue, root.warningThreshold, root.minValue]
            delegate: Text {
                required property real modelData
                x: gaugeArea.tubeX + gaugeArea.tubeWidth + Theme.px(11)
                y: gaugeArea.yFor(modelData) - height / 2
                text: Math.round(root.toDisplay(modelData))
                color: Theme.textSecondary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSmall
            }
        }
    }
}

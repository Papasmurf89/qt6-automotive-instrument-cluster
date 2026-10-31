// Primary gauge: speed in km/h or mph (Theme.imperial), digital readout and
// gear indicator in the dial centre.
import QtQuick
import Dashboard

Gauge {
    id: root

    property real speedKmh: 0
    property int gear: VehicleData.Park
    property int gearNumber: 0

    value: Theme.speed(speedKmh)
    minValue: 0
    maxValue: Theme.imperial ? 160 : 240
    majorStep: 20
    minorDivisions: 4
    needleVelocity: Theme.imperial ? 100 : 160

    Text {
        id: digital
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.verticalCenter
        anchors.bottomMargin: -root.dialRadius * 0.12
        text: Math.round(root.sweeping ? root.shownValue : Theme.speed(root.speedKmh))
        color: Theme.textPrimary
        font.family: Theme.fontFamily
        font.pixelSize: Math.round(root.dialRadius * 0.36)
        font.bold: true
    }

    Text {
        id: unitLabel
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: digital.bottom
        anchors.topMargin: -root.dialRadius * 0.03
        text: Theme.speedUnit
        color: Theme.textSecondary
        font.family: Theme.fontFamily
        font.pixelSize: Math.max(14, Math.round(root.dialRadius * 0.10))
    }

    GearIndicator {
        anchors.horizontalCenter: parent.horizontalCenter
        // Sits in the open bottom segment of the dial
        y: parent.height / 2 + root.dialRadius * 0.62 - height
        gear: root.gear
        gearNumber: root.gearNumber
        fontSize: Math.max(14, Math.round(root.dialRadius * 0.10))
    }
}

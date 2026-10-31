// Bottom bar: odometer, trip A/B (long-press to reset) and range estimate.
import QtQuick
import Dashboard

Rectangle {
    id: root

    implicitHeight: Theme.infoBarHeight
    color: Theme.surface

    Rectangle {
        anchors.top: parent.top
        width: parent.width
        height: 1
        color: Theme.border
    }

    Row {
        id: cells
        anchors.fill: parent
        anchors.leftMargin: Theme.margin
        anchors.rightMargin: Theme.margin
        readonly property real cellWidth: width / 4

        InfoItem {
            width: cells.cellWidth
            height: cells.height
            label: "ODO"
            value: Math.floor(Theme.distance(VehicleData.odometer)).toString()
            unit: Theme.distanceUnit
        }
        InfoItem {
            width: cells.cellWidth
            height: cells.height
            label: "TRIP A"
            value: Theme.distance(VehicleData.tripA).toFixed(1)
            unit: Theme.distanceUnit
            onLongPressed: VehicleData.resetTripA()
        }
        InfoItem {
            width: cells.cellWidth
            height: cells.height
            label: "TRIP B"
            value: Theme.distance(VehicleData.tripB).toFixed(1)
            unit: Theme.distanceUnit
            onLongPressed: VehicleData.resetTripB()
        }
        InfoItem {
            width: cells.cellWidth
            height: cells.height
            label: "RANGE"
            value: Math.round(Theme.distance(VehicleData.range)).toString()
            unit: Theme.distanceUnit
        }
    }
}

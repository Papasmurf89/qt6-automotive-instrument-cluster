// Row of warning lamps bound to VehicleData. `lampTest` lights every lamp
// (bulb check during the startup sweep, as in a real cluster).
// Lamps are explicit instances (not a Repeater over a JS array) so a change
// of one flag only touches that one lamp's binding.
import QtQuick
import Dashboard

Item {
    id: root

    property bool lampTest: false
    property bool blinkPhase: true

    implicitHeight: Theme.telltaleBarHeight

    Row {
        anchors.centerIn: parent
        spacing: Theme.px(14)

        TelltaleIcon {
            source: Theme.iconPath + "check_engine.svg"
            active: root.lampTest || VehicleData.checkEngine
            fallbackText: "ENG"; fallbackColor: Theme.warning
        }
        TelltaleIcon {
            source: Theme.iconPath + "oil_pressure.svg"
            active: root.lampTest || VehicleData.oilPressureWarning
            fallbackText: "OIL"; fallbackColor: Theme.critical
        }
        TelltaleIcon {
            source: Theme.iconPath + "battery.svg"
            active: root.lampTest || VehicleData.batteryWarning
            fallbackText: "BAT"; fallbackColor: Theme.critical
        }
        TelltaleIcon {
            source: Theme.iconPath + "abs.svg"
            active: root.lampTest || VehicleData.absWarning
            fallbackText: "ABS"; fallbackColor: Theme.warning
        }
        TelltaleIcon {
            source: Theme.iconPath + "parking_brake.svg"
            active: root.lampTest || VehicleData.parkingBrake
            fallbackText: "(P)"; fallbackColor: Theme.critical
        }
        TelltaleIcon {
            source: Theme.iconPath + "seatbelt.svg"
            active: root.lampTest || VehicleData.seatbeltWarning
            blinking: !root.lampTest
            blinkPhase: root.blinkPhase
            fallbackText: "BELT"; fallbackColor: Theme.critical
        }
        TelltaleIcon {
            source: Theme.iconPath + "door_open.svg"
            active: root.lampTest || VehicleData.doorOpen
            fallbackText: "DOOR"; fallbackColor: Theme.critical
        }
        TelltaleIcon {
            source: Theme.iconPath + "hazard.svg"
            active: root.lampTest || VehicleData.hazard
            blinking: !root.lampTest
            blinkPhase: root.blinkPhase
            fallbackText: "HAZ"; fallbackColor: Theme.critical
        }
        TelltaleIcon {
            source: Theme.iconPath + "low_beam.svg"
            active: root.lampTest || VehicleData.lowBeam
            fallbackText: "LO"; fallbackColor: Theme.ok
        }
        TelltaleIcon {
            source: Theme.iconPath + "high_beam.svg"
            active: root.lampTest || VehicleData.highBeam
            fallbackText: "HI"; fallbackColor: Theme.cold
        }
    }
}

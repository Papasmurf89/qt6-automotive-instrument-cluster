// Root window. Designed for 800x480; every size is derived from the window
// size through Theme.scale and anchors, so 1024x600 or 1280x480 work as-is.
//
//  +----------------------------------------------------------------------+
//  | <-  12:34 Thu 15 Oct      [km/h] [NIGHT]          OUT 21.5 °C     ->  | StatusBar
//  |        (ENG)(OIL)(BAT)(ABS)(P)(BELT)(DOOR)(HAZ)(LO)(HI)              | TelltaleBar
//  |  .--------.         .------------.         +-------+ +-------+       |
//  | |  TACHO   |       |  SPEEDO      |        |COOLANT| | BOARD |       |
//  | |          |       |    88 km/h   |        |  90°C | |  45°C |       |
//  |  '--------'        |  P R N D M 4 |        |  |#|  | |  |#|  |       |
//  |  [fuel ======   ]   '------------'         |  (o)  | |  (o)  |       |
//  |  [batt ======   ]                          +-------+ +-------+       |
//  | ODO 48213 km | TRIP A 312.7 km | TRIP B 27.9 km | RANGE 228 km        | InfoBar
//  +----------------------------------------------------------------------+
import QtQuick
import Dashboard

Window {
    id: window

    width: Theme.baseWidth
    height: Theme.baseHeight
    // Shown by main.cpp (fullscreen or windowed) - never hard-coded here.
    visible: false
    title: qsTr("Dashboard")
    color: Theme.background

    // Startup gauge sweep 0 -> 1 -> 0, then live data (-1).
    property real sweepFraction: 0
    readonly property bool lampTest: sweepFraction >= 0
    // Shared blink clock for indicators/hazard; runs only while needed.
    property bool blinkPhase: true

    Binding { target: Theme; property: "windowWidth"; value: window.width }
    Binding { target: Theme; property: "windowHeight"; value: window.height }

    SequentialAnimation {
        running: true
        PauseAnimation { duration: 250 }
        NumberAnimation {
            target: window; property: "sweepFraction"
            from: 0; to: 1; duration: 900; easing.type: Easing.InOutCubic
        }
        PauseAnimation { duration: 150 }
        NumberAnimation {
            target: window; property: "sweepFraction"
            to: 0; duration: 700; easing.type: Easing.InOutCubic
        }
        ScriptAction { script: window.sweepFraction = -1 }
    }

    Timer {
        interval: 380   // ~80 flashes/min, inside the ECE R6 range (60-120)
        repeat: true
        running: VehicleData.leftIndicator || VehicleData.rightIndicator || VehicleData.hazard
                 || VehicleData.seatbeltWarning
        onRunningChanged: window.blinkPhase = true
        onTriggered: window.blinkPhase = !window.blinkPhase
    }

    Item {
        id: root
        anchors.fill: parent
        focus: true

        // Dev/test shortcuts: U = units, T = theme, Ctrl+Q = quit
        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_U) {
                Theme.imperial = !Theme.imperial
                event.accepted = true
            } else if (event.key === Qt.Key_T) {
                Theme.night = !Theme.night
                event.accepted = true
            } else if (event.key === Qt.Key_Q && (event.modifiers & Qt.ControlModifier)) {
                Qt.quit()
                event.accepted = true
            }
        }

        StatusBar {
            id: statusBar
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: Theme.statusBarHeight
            blinkPhase: window.blinkPhase
            lampTest: window.lampTest
        }

        TelltaleBar {
            id: telltales
            anchors.top: statusBar.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: Theme.telltaleBarHeight
            lampTest: window.lampTest
            blinkPhase: window.blinkPhase
        }

        InfoBar {
            id: infoBar
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: Theme.infoBarHeight
        }

        // ---- Main gauge area ------------------------------------------------
        Item {
            id: mainArea
            anchors.top: telltales.bottom
            anchors.bottom: infoBar.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: Theme.margin

            readonly property real leftWidth: Math.round(width * 0.31)
            readonly property real centreWidth: Math.round(width * 0.43)

            // Left column: tachometer + fuel/battery bars
            Item {
                id: leftColumn
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: mainArea.leftWidth

                Column {
                    id: bars
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.leftMargin: Theme.px(10)
                    anchors.rightMargin: Theme.px(10)
                    spacing: Theme.px(6)

                    BarGauge {
                        width: parent.width
                        height: Theme.px(40)
                        label: "FUEL"
                        unit: "%"
                        value: VehicleData.fuelLevel
                        lowThreshold: 15
                        iconSource: Theme.iconPath + "fuel.svg"
                    }
                    BarGauge {
                        width: parent.width
                        height: Theme.px(40)
                        label: "BATTERY"
                        unit: "V"
                        decimals: 1
                        value: VehicleData.batteryVoltage
                        minValue: 10
                        maxValue: 16
                        lowThreshold: 11.8
                        highThreshold: 15.2
                        iconSource: Theme.iconPath + "battery_level.svg"
                        normalColor: Theme.ok
                    }
                }

                Tachometer {
                    anchors.top: parent.top
                    anchors.bottom: bars.top
                    anchors.bottomMargin: Theme.px(6)
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: Math.min(parent.width, height)
                    rpm: VehicleData.rpm
                    sweepFraction: window.sweepFraction
                }
            }

            // Centre: speedometer (primary)
            Speedometer {
                id: speedometer
                anchors.left: leftColumn.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: mainArea.centreWidth
                speedKmh: VehicleData.speed
                gear: VehicleData.gear
                gearNumber: VehicleData.gearNumber
                sweepFraction: window.sweepFraction
            }

            // Right column: two instances of the reusable TemperatureWidget
            Row {
                anchors.left: speedometer.right
                anchors.leftMargin: Theme.px(10)
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                spacing: Theme.px(8)
                readonly property real cellWidth: (width - spacing) / 2

                TemperatureWidget {
                    width: parent.cellWidth
                    height: parent.height
                    label: "COOLANT"
                    value: VehicleData.coolantTemperature
                    minValue: 40
                    maxValue: 130
                    coldThreshold: 60
                    warningThreshold: 105
                    criticalThreshold: 115
                    unit: Theme.temperatureUnit
                }
                TemperatureWidget {
                    width: parent.cellWidth
                    height: parent.height
                    label: "BOARD"
                    value: TemperatureProvider.temperature
                    valid: TemperatureProvider.valid
                    minValue: 0
                    maxValue: 100
                    coldThreshold: 15
                    warningThreshold: 60
                    criticalThreshold: 72
                    decimals: 1
                    unit: Theme.temperatureUnit
                }
            }
        }
    }
}

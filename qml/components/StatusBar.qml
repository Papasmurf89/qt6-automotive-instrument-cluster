// Top bar: turn signals at the outer edges, clock, outside temperature and
// touch-toggles for units (km/h <-> mph) and day/night theme.
import QtQuick
import Dashboard

Rectangle {
    id: root

    property bool blinkPhase: true
    property bool lampTest: false

    implicitHeight: Theme.statusBarHeight
    color: Theme.surface

    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: 1
        color: Theme.border
    }

    TurnSignal {
        id: leftSignal
        anchors.left: parent.left
        anchors.leftMargin: Theme.margin
        anchors.verticalCenter: parent.verticalCenter
        active: root.lampTest || VehicleData.leftIndicator || VehicleData.hazard
        blinking: !root.lampTest
        blinkPhase: root.blinkPhase
    }

    // Clock: one cheap timer, the text only changes once a minute.
    Text {
        id: clock
        anchors.left: leftSignal.right
        anchors.leftMargin: Theme.px(16)
        anchors.verticalCenter: parent.verticalCenter
        color: Theme.textPrimary
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontMedium
        font.bold: true

        function refresh() {
            const now = new Date()
            text = Qt.formatTime(now, "hh:mm")
            date.text = Qt.formatDate(now, "ddd d MMM")
        }
        Timer {
            interval: 1000
            running: true
            repeat: true
            triggeredOnStart: true
            onTriggered: clock.refresh()
        }
    }
    Text {
        id: date
        anchors.left: clock.right
        anchors.leftMargin: Theme.px(10)
        anchors.verticalCenter: parent.verticalCenter
        color: Theme.textSecondary
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSmall
    }

    // Centre toggles (touch friendly; also bound to keys U / T in Main.qml)
    Row {
        anchors.centerIn: parent
        spacing: Theme.px(8)

        Rectangle {
            width: unitText.implicitWidth + Theme.px(18)
            height: Theme.px(26)
            radius: height / 2
            color: Theme.surfaceAlt
            border.color: Theme.border
            Text {
                id: unitText
                anchors.centerIn: parent
                text: Theme.speedUnit
                color: Theme.accent
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSmall
                font.bold: true
            }
            MouseArea {
                anchors.fill: parent
                anchors.margins: -Theme.px(6)
                onClicked: Theme.imperial = !Theme.imperial
            }
        }
        Rectangle {
            width: themeText.implicitWidth + Theme.px(18)
            height: Theme.px(26)
            radius: height / 2
            color: Theme.surfaceAlt
            border.color: Theme.border
            Text {
                id: themeText
                anchors.centerIn: parent
                text: Theme.night ? "NIGHT" : "DAY"
                color: Theme.accent
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSmall
                font.bold: true
            }
            MouseArea {
                anchors.fill: parent
                anchors.margins: -Theme.px(6)
                onClicked: Theme.night = !Theme.night
            }
        }
    }

    Text {
        id: outsideLabel
        anchors.right: outsideTemp.left
        anchors.rightMargin: Theme.px(6)
        anchors.verticalCenter: parent.verticalCenter
        text: "OUT"
        color: Theme.textSecondary
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSmall
    }
    Text {
        id: outsideTemp
        anchors.right: rightSignal.left
        anchors.rightMargin: Theme.px(16)
        anchors.verticalCenter: parent.verticalCenter
        text: Theme.temperature(VehicleData.outsideTemperature).toFixed(1) + " " + Theme.temperatureUnit
        color: Theme.textPrimary
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontMedium
        font.bold: true
    }

    TurnSignal {
        id: rightSignal
        pointsRight: true
        anchors.right: parent.right
        anchors.rightMargin: Theme.margin
        anchors.verticalCenter: parent.verticalCenter
        active: root.lampTest || VehicleData.rightIndicator || VehicleData.hazard
        blinking: !root.lampTest
        blinkPhase: root.blinkPhase
    }
}

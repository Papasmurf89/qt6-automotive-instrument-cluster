// Engine speed gauge (x1000 r/min) with a red zone.
import QtQuick
import Dashboard

Gauge {
    id: root

    property real rpm: 0
    property real redlineRpm: 6500

    value: rpm
    minValue: 0
    maxValue: 8000
    majorStep: 1000
    minorDivisions: 4
    labelDivisor: 1000
    redlineEnabled: true
    redlineFrom: redlineRpm
    needleVelocity: 9000
    arcColor: rpm >= redlineRpm ? Theme.redline : Theme.accent

    Text {
        id: digital
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.verticalCenter
        anchors.bottomMargin: -root.dialRadius * 0.10
        text: Math.round((root.sweeping ? root.shownValue : root.rpm) / 10) * 10
        color: root.rpm >= root.redlineRpm ? Theme.redline : Theme.textPrimary
        font.family: Theme.fontFamily
        font.pixelSize: Math.max(16, Math.round(root.dialRadius * 0.24))
        font.bold: true
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: digital.bottom
        text: "r/min"
        color: Theme.textSecondary
        font.family: Theme.fontFamily
        font.pixelSize: 14
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height / 2 + root.dialRadius * 0.62 - height
        text: "x1000"
        color: Theme.textDim
        font.family: Theme.fontFamily
        font.pixelSize: 14
    }
}

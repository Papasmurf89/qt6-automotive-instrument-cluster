// Label + value + unit cell used in the bottom info bar.
import QtQuick
import Dashboard

Item {
    id: root

    property string label
    property string value
    property string unit
    signal longPressed()

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    Row {
        id: row
        anchors.centerIn: parent
        spacing: Theme.px(6)

        Text {
            anchors.baseline: valueText.baseline
            text: root.label
            color: Theme.textSecondary
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSmall
        }
        Text {
            id: valueText
            text: root.value
            color: Theme.textPrimary
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontMedium
            font.bold: true
        }
        Text {
            anchors.baseline: valueText.baseline
            text: root.unit
            color: Theme.textSecondary
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSmall
        }
    }

    MouseArea {
        anchors.fill: parent
        onPressAndHold: root.longPressed()
    }
}

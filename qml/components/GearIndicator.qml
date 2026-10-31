// Selector display "P R N D M" with the active position highlighted, plus the
// engaged gear number while driving in D (automatic) or M (manual/sport).
pragma ComponentBehavior: Bound
import QtQuick
import Dashboard

Row {
    id: root

    property int gear: VehicleData.Park        // VehicleData.Gear enum value
    property int gearNumber: 0                 // 0 = not shown
    property real fontSize: Theme.fontMedium

    spacing: Math.round(fontSize * 0.35)
    // All cells share one height and bottom-align so mixed sizes line up.
    readonly property real cellHeight: Math.round(fontSize * 1.35 * 1.2)

    Repeater {
        model: ["P", "R", "N", "D", "M"]
        delegate: Text {
            required property string modelData
            required property int index
            readonly property bool active: root.gear === index   // enum order matches the list
            height: root.cellHeight
            verticalAlignment: Text.AlignBottom
            text: modelData
            color: active ? Theme.accent : Theme.textDim
            font.family: Theme.fontFamily
            font.pixelSize: active ? Math.round(root.fontSize * 1.35) : root.fontSize
            font.bold: active
        }
    }

    Text {
        height: root.cellHeight
        verticalAlignment: Text.AlignBottom
        visible: root.gearNumber > 0 && (root.gear === VehicleData.Drive || root.gear === VehicleData.Manual)
        text: root.gearNumber
        color: Theme.textPrimary
        font.family: Theme.fontFamily
        font.pixelSize: Math.round(root.fontSize * 1.35)
        font.bold: true
    }
}

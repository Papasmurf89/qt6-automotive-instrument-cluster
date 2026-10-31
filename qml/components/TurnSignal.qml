// Left or right turn indicator arrow (green, blinking while active).
import QtQuick
import Dashboard

TelltaleIcon {
    id: root

    property bool pointsRight: false   // false = left arrow

    source: Theme.iconPath + (pointsRight ? "turn_right.svg" : "turn_left.svg")
    blinking: true
    fallbackText: pointsRight ? ">" : "<"
    fallbackColor: Theme.ok
    size: Theme.px(30)
}

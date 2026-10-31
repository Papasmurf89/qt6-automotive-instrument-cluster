// Gauge needle. Fills the gauge and rotates around its centre, so a value
// change is just a transform update - no re-tessellation, no repaint.
// With innerRadius > 0 it is drawn as a "ring pointer" (only the outer part
// of the dial) so the digital readout in the centre stays unobstructed.
import QtQuick
import Dashboard

Item {
    id: root

    property real angle: 0          // degrees, 0 = 12 o'clock, clockwise
    property real length: 100       // centre to tip
    property real innerRadius: 0    // centre to the start of the pointer
    property real thickness: 4
    property color color: Theme.needle

    rotation: angle
    transformOrigin: Item.Center

    Rectangle {
        x: root.width / 2 - width / 2
        y: root.height / 2 - root.length
        width: root.thickness
        height: root.length - root.innerRadius
        radius: width / 2
        color: root.color
        antialiasing: true
    }
}

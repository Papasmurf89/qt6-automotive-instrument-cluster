// Compact segmented bar gauge (fuel, battery voltage). Segments are plain
// Rectangles - trivially cheap on both GPU and software rendering.
pragma ComponentBehavior: Bound
import QtQuick
import Dashboard

Item {
    id: root

    property real value: 0
    property real minValue: 0
    property real maxValue: 100
    property real lowThreshold: minValue    // value below -> warning colour
    property real highThreshold: maxValue   // value above -> warning colour
    property string label: ""
    property string unit: ""
    property int decimals: 0
    property url iconSource
    property int segments: 12
    property color normalColor: Theme.accent

    readonly property bool outOfRange: value < lowThreshold || value > highThreshold
    readonly property color activeColor: outOfRange ? Theme.warning : normalColor
    property real fraction: Math.max(0, Math.min(1, (value - minValue) / Math.max(1e-6, maxValue - minValue)))
    Behavior on fraction { SmoothedAnimation { duration: 500; velocity: -1 } }

    implicitWidth: Theme.px(230)
    implicitHeight: Theme.px(44)

    Image {
        id: icon
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: Theme.px(22)
        height: width
        sourceSize: Qt.size(width, height)
        source: root.iconSource
        fillMode: Image.PreserveAspectFit
        opacity: root.outOfRange ? 1.0 : 0.8
    }

    Text {
        id: labelText
        anchors.left: icon.right
        anchors.leftMargin: Theme.px(6)
        anchors.top: parent.top
        text: root.label
        color: Theme.textSecondary
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSmall
    }

    Text {
        id: valueText
        anchors.right: parent.right
        anchors.top: parent.top
        text: root.value.toFixed(root.decimals) + (root.unit.length ? " " + root.unit : "")
        color: root.outOfRange ? Theme.warning : Theme.textPrimary
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontNormal
        font.bold: true
    }

    Row {
        id: bar
        anchors.left: labelText.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Theme.px(2)
        height: Theme.px(10)
        spacing: Theme.px(3)
        readonly property real segmentWidth: (width - spacing * (root.segments - 1)) / root.segments

        Repeater {
            model: root.segments
            delegate: Rectangle {
                required property int index
                width: bar.segmentWidth
                height: bar.height
                radius: Theme.px(2)
                color: (index + 0.5) / root.segments <= root.fraction ? root.activeColor : Theme.gaugeTrack
            }
        }
    }
}

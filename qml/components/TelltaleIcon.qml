// One warning/indicator lamp. The SVG carries its own ISO colour; an inactive
// lamp is shown as a faint "ghost" so the driver knows where it lives.
// If the SVG cannot be loaded (e.g. the qsvg image plugin is missing on the
// target) a short coloured text label is shown instead.
import QtQuick
import Dashboard

Item {
    id: root

    property url source
    property bool active: false
    property bool blinking: false       // blink with blinkPhase while active
    property bool blinkPhase: true
    property string fallbackText: ""
    property color fallbackColor: Theme.warning
    property real size: Theme.telltaleSize

    readonly property bool lit: active && (!blinking || blinkPhase)

    implicitWidth: size
    implicitHeight: size
    opacity: lit ? 1.0 : Theme.telltaleOffOpacity

    Image {
        id: image
        anchors.fill: parent
        source: root.source
        sourceSize: Qt.size(root.size, root.size)   // rasterise once at display size
        fillMode: Image.PreserveAspectFit
        smooth: true
    }

    Text {
        anchors.centerIn: parent
        visible: image.status === Image.Error
        text: root.fallbackText
        color: root.fallbackColor
        font.family: Theme.fontFamily
        font.pixelSize: 14
        font.bold: true
    }
}

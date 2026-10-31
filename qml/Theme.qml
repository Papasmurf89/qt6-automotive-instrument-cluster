// Central style: base resolution, scaling, colours, fonts, unit conversion.
// Change baseWidth/baseHeight here to retarget the design resolution.
pragma Singleton
import QtQuick

QtObject {
    id: theme

    // ---- Resolution & scaling -------------------------------------------
    readonly property int baseWidth: 800
    readonly property int baseHeight: 480
    // Updated by Main.qml from the real window size (compositor may resize).
    property real windowWidth: baseWidth
    property real windowHeight: baseHeight
    readonly property real scale: Math.max(0.5, Math.min(windowWidth / baseWidth, windowHeight / baseHeight))

    function px(v: real): real { return Math.round(v * scale) }
    // Fonts never go below 14 px (readability requirement for secondary info).
    function fontPx(v: real): real { return Math.max(14, Math.round(v * scale)) }

    // ---- User preferences -------------------------------------------------
    // Start-up defaults from the command line (--day, --imperial); toggled at
    // runtime by the status bar chips or the T / U keys.
    property bool night: Qt.application.arguments.indexOf("--day") < 0
    property bool imperial: Qt.application.arguments.indexOf("--imperial") >= 0

    // ---- Fonts --------------------------------------------------------------
    // Liberation Sans ships in the target sysroot; if it is missing fall back
    // to the fontconfig "sans-serif" alias so text never disappears.
    readonly property string fontFamily: Qt.fontFamilies().indexOf("Liberation Sans") >= 0
                                         ? "Liberation Sans" : "sans-serif"

    readonly property real fontSmall: fontPx(14)
    readonly property real fontNormal: fontPx(16)
    readonly property real fontMedium: fontPx(19)
    readonly property real fontLarge: fontPx(24)

    // ---- Layout metrics (designed for 800x480) -----------------------------
    readonly property real margin: px(8)
    readonly property real spacing: px(8)
    readonly property real statusBarHeight: px(40)
    readonly property real telltaleBarHeight: px(36)
    readonly property real infoBarHeight: px(46)
    readonly property real telltaleSize: px(26)
    readonly property real radius: px(6)

    // ---- Colours -------------------------------------------------------------
    readonly property color background:    night ? "#07090c" : "#e6eaee"
    readonly property color surface:       night ? "#10141a" : "#f7f9fb"
    readonly property color surfaceAlt:    night ? "#171c23" : "#ffffff"
    readonly property color border:        night ? "#232a33" : "#c6ced6"
    readonly property color textPrimary:   night ? "#e9eef3" : "#11161c"
    readonly property color textSecondary: night ? "#8d99a6" : "#4b5662"
    readonly property color textDim:       night ? "#4f5a66" : "#97a2ad"
    readonly property color accent:        night ? "#2fb6ff" : "#0076c6"
    readonly property color needle:        night ? "#ff5a36" : "#e0301e"
    readonly property color gaugeFace:     night ? "#0d1116" : "#fdfdfe"
    readonly property color gaugeTrack:    night ? "#1b222b" : "#d9dee4"
    readonly property color tickMajor:     night ? "#dfe6ee" : "#1d242c"
    readonly property color tickMinor:     night ? "#5b6672" : "#8b95a0"
    readonly property color redline:       "#e5322d"

    // Status colours (also used by telltales, ISO 2575 colour meaning)
    readonly property color cold:     night ? "#4c8dff" : "#2a6be0"
    readonly property color ok:       night ? "#36c46b" : "#1f9d50"
    readonly property color warning:  "#ffb000"
    readonly property color critical: "#ff3b30"
    readonly property color telltaleOffColor: night ? "#1d242c" : "#d4dae0"
    readonly property real telltaleOffOpacity: night ? 0.16 : 0.22

    readonly property string iconPath: "qrc:/qt/qml/Dashboard/resources/icons/"

    // ---- Unit conversion (backend is always metric) -------------------------
    readonly property string speedUnit: imperial ? "mph" : "km/h"
    readonly property string distanceUnit: imperial ? "mi" : "km"
    readonly property string temperatureUnit: imperial ? "°F" : "°C"

    function speed(kmh: real): real { return imperial ? kmh * 0.621371 : kmh }
    function distance(km: real): real { return imperial ? km * 0.621371 : km }
    function temperature(celsius: real): real { return imperial ? celsius * 9 / 5 + 32 : celsius }
}

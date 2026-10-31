# Qt 6 Quick instrument cluster - builds against any Qt >= 6.5.
cmake_minimum_required(VERSION 3.21)

project(dashboard
    VERSION 1.0.0
    DESCRIPTION "Qt Quick automotive instrument cluster"
    LANGUAGES CXX)

# DEMO data source. Production: -DDASHBOARD_ENABLE_SIMULATOR=OFF removes the
# simulator sources from the binary entirely.
option(DASHBOARD_ENABLE_SIMULATOR "Build the demo vehicle data simulator" ON)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

find_package(Qt6 6.5 REQUIRED COMPONENTS Core Gui Qml Quick)

qt_standard_project_setup(REQUIRES 6.5)
# Qt >= 6.8: generate qmldir files for qml/ and qml/components/ so files in
# those sub-directories implicitly see the whole Dashboard module.
if(QT_KNOWN_POLICY_QTP0004)
    qt_policy(SET QTP0004 NEW)
endif()

qt_add_executable(dashboard
    src/main.cpp
)

set_source_files_properties(qml/Theme.qml PROPERTIES QT_QML_SINGLETON_TYPE TRUE)

qt_add_qml_module(dashboard
    URI Dashboard
    VERSION 1.0
    QML_FILES
        qml/Main.qml
        qml/Theme.qml
        qml/components/BarGauge.qml
        qml/components/Gauge.qml
        qml/components/GearIndicator.qml
        qml/components/InfoBar.qml
        qml/components/InfoItem.qml
        qml/components/Needle.qml
        qml/components/Speedometer.qml
        qml/components/StatusBar.qml
        qml/components/Tachometer.qml
        qml/components/TelltaleBar.qml
        qml/components/TelltaleIcon.qml
        qml/components/TemperatureWidget.qml
        qml/components/TurnSignal.qml
        qml/components/ValueArc.qml
    SOURCES
        src/vehicledata.h src/vehicledata.cpp
        src/temperatureprovider.h src/temperatureprovider.cpp
    RESOURCES
        resources/icons/abs.svg
        resources/icons/battery.svg
        resources/icons/battery_level.svg
        resources/icons/check_engine.svg
        resources/icons/door_open.svg
        resources/icons/fuel.svg
        resources/icons/hazard.svg
        resources/icons/high_beam.svg
        resources/icons/low_beam.svg
        resources/icons/oil_pressure.svg
        resources/icons/parking_brake.svg
        resources/icons/seatbelt.svg
        resources/icons/turn_left.svg
        resources/icons/turn_right.svg
)

# The generated QML type registration includes the headers by bare name.
target_include_directories(dashboard PRIVATE src)

if(DASHBOARD_ENABLE_SIMULATOR)
    target_sources(dashboard PRIVATE
        src/simulator/vehiclesimulator.h
        src/simulator/vehiclesimulator.cpp)
    target_compile_definitions(dashboard PRIVATE DASHBOARD_ENABLE_SIMULATOR)
endif()

target_compile_definitions(dashboard PRIVATE
    DASHBOARD_VERSION="${PROJECT_VERSION}"
    $<$<CONFIG:Release>:QT_NO_DEBUG_OUTPUT>)

target_compile_options(dashboard PRIVATE -Wall -Wextra -Wpedantic)

target_link_libraries(dashboard PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
)

include(GNUInstallDirs)
install(TARGETS dashboard
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

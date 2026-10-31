#include "vehicledata.h"

#include <QJSEngine>
#include <QQmlEngine>

#include <algorithm>
#include <cmath>

namespace {
VehicleData *s_instance = nullptr;

// Changes smaller than this are not forwarded to QML. They are invisible on
// an 800x480 screen but would still cost a binding evaluation each.
constexpr double kSpeedEpsilon = 0.01;  // km/h
constexpr double kRpmEpsilon = 1.0;     // 1/min
constexpr double kLevelEpsilon = 0.01;  // %, V, degC
constexpr double kDistanceEpsilon = 0.001; // km (1 m)
} // namespace

VehicleData::VehicleData(QObject *parent)
    : QObject(parent)
{
    if (s_instance)
        qFatal("VehicleData: only one instance may exist");
    s_instance = this;
}

VehicleData::~VehicleData()
{
    if (s_instance == this)
        s_instance = nullptr;
}

VehicleData *VehicleData::create(QQmlEngine *qmlEngine, QJSEngine *jsEngine)
{
    Q_UNUSED(qmlEngine)
    if (!s_instance)
        qFatal("VehicleData::create: instantiate VehicleData in main() before loading QML");
    Q_ASSERT(jsEngine->thread() == s_instance->thread());
    // The object is owned by main(); stop the QML engine from deleting it.
    QJSEngine::setObjectOwnership(s_instance, QJSEngine::CppOwnership);
    return s_instance;
}

VehicleData *VehicleData::instance()
{
    return s_instance;
}

template<typename T>
void VehicleData::assign(T &member, T value, void (VehicleData::*notify)())
{
    if (member == value)
        return;
    member = value;
    emit (this->*notify)();
}

void VehicleData::assign(double &member, double value, double epsilon, void (VehicleData::*notify)())
{
    if (!std::isfinite(value) || std::abs(member - value) < epsilon)
        return;
    member = value;
    emit (this->*notify)();
}

void VehicleData::resetTripA() { setTripA(0.0); }
void VehicleData::resetTripB() { setTripB(0.0); }

void VehicleData::setSpeed(double kmh) { assign(m_speed, std::max(0.0, kmh), kSpeedEpsilon, &VehicleData::speedChanged); }
void VehicleData::setRpm(double rpm) { assign(m_rpm, std::max(0.0, rpm), kRpmEpsilon, &VehicleData::rpmChanged); }
void VehicleData::setGear(Gear gear) { assign(m_gear, gear, &VehicleData::gearChanged); }
void VehicleData::setGearNumber(int gearNumber) { assign(m_gearNumber, gearNumber, &VehicleData::gearNumberChanged); }
void VehicleData::setFuelLevel(double percent) { assign(m_fuelLevel, std::clamp(percent, 0.0, 100.0), kLevelEpsilon, &VehicleData::fuelLevelChanged); }
void VehicleData::setBatteryVoltage(double volts) { assign(m_batteryVoltage, volts, kLevelEpsilon, &VehicleData::batteryVoltageChanged); }
void VehicleData::setCoolantTemperature(double celsius) { assign(m_coolantTemperature, celsius, kLevelEpsilon, &VehicleData::coolantTemperatureChanged); }
void VehicleData::setOutsideTemperature(double celsius) { assign(m_outsideTemperature, celsius, kLevelEpsilon, &VehicleData::outsideTemperatureChanged); }
void VehicleData::setOdometer(double km) { assign(m_odometer, km, kDistanceEpsilon, &VehicleData::odometerChanged); }
void VehicleData::setTripA(double km) { assign(m_tripA, km, kDistanceEpsilon, &VehicleData::tripAChanged); }
void VehicleData::setTripB(double km) { assign(m_tripB, km, kDistanceEpsilon, &VehicleData::tripBChanged); }
void VehicleData::setRange(double km) { assign(m_range, std::max(0.0, km), kDistanceEpsilon, &VehicleData::rangeChanged); }
void VehicleData::setLeftIndicator(bool on) { assign(m_leftIndicator, on, &VehicleData::leftIndicatorChanged); }
void VehicleData::setRightIndicator(bool on) { assign(m_rightIndicator, on, &VehicleData::rightIndicatorChanged); }
void VehicleData::setHazard(bool on) { assign(m_hazard, on, &VehicleData::hazardChanged); }
void VehicleData::setCheckEngine(bool on) { assign(m_checkEngine, on, &VehicleData::checkEngineChanged); }
void VehicleData::setOilPressureWarning(bool on) { assign(m_oilPressureWarning, on, &VehicleData::oilPressureWarningChanged); }
void VehicleData::setBatteryWarning(bool on) { assign(m_batteryWarning, on, &VehicleData::batteryWarningChanged); }
void VehicleData::setAbsWarning(bool on) { assign(m_absWarning, on, &VehicleData::absWarningChanged); }
void VehicleData::setSeatbeltWarning(bool on) { assign(m_seatbeltWarning, on, &VehicleData::seatbeltWarningChanged); }
void VehicleData::setParkingBrake(bool on) { assign(m_parkingBrake, on, &VehicleData::parkingBrakeChanged); }
void VehicleData::setHighBeam(bool on) { assign(m_highBeam, on, &VehicleData::highBeamChanged); }
void VehicleData::setLowBeam(bool on) { assign(m_lowBeam, on, &VehicleData::lowBeamChanged); }
void VehicleData::setDoorOpen(bool on) { assign(m_doorOpen, on, &VehicleData::doorOpenChanged); }

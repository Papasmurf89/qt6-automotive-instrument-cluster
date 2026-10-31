// DEMO/TEST ONLY - see vehiclesimulator.h.
#include "vehiclesimulator.h"

#include "../temperatureprovider.h"
#include "../vehicledata.h"

#include <QRandomGenerator>

#include <algorithm>
#include <array>
#include <cmath>

namespace {
constexpr int kTickMs = 50;          // 20 Hz: plenty, the QML needles interpolate
constexpr double kSlowTickS = 1.0;   // temperatures, fuel, range
constexpr double kIdleRpm = 780.0;
constexpr double kTankLitres = 50.0;
constexpr double kConsumptionL100 = 6.8;
constexpr double kPi = 3.14159265358979323846;

// rpm per km/h for gears 1..6
constexpr std::array<double, 7> kGearFactor = {0.0, 105.0, 62.0, 43.0, 33.0, 27.0, 23.0};

double noise(double amplitude)
{
    return (QRandomGenerator::global()->generateDouble() * 2.0 - 1.0) * amplitude;
}
} // namespace

VehicleSimulator::VehicleSimulator(VehicleData *vehicle, TemperatureProvider *temperature, QObject *parent)
    : QObject(parent)
    , m_vehicle(vehicle)
    , m_temperature(temperature)
{
    m_timer.setTimerType(Qt::PreciseTimer);
    m_timer.setInterval(kTickMs);
    connect(&m_timer, &QTimer::timeout, this, &VehicleSimulator::tick);
}

void VehicleSimulator::start()
{
    m_vehicle->setOdometer(m_odometer);
    m_vehicle->setTripA(m_tripA);
    m_vehicle->setTripB(m_tripB);
    m_vehicle->setOutsideTemperature(21.5);
    enterPhase(0);
    slowTick(0.0);
    m_clock.start();
    m_lastMs = 0;
    m_timer.start();
}

void VehicleSimulator::stop()
{
    m_timer.stop();
}

void VehicleSimulator::enterPhase(int index)
{
    static constexpr std::array<PhaseSpec, static_cast<int>(Phase::Count)> kScript = {{
        {Phase::EngineOff, 3.0},
        {Phase::Idle, 3.0},
        {Phase::CityDrive, 12.0},
        {Phase::Cruise, 10.0},
        {Phase::Slowdown, 6.0},
        {Phase::SportRun, 9.0},
        {Phase::Braking, 8.0},
        {Phase::HazardStop, 4.0},
        {Phase::Reverse, 4.0},
    }};

    m_phaseIndex = index % static_cast<int>(kScript.size());
    m_phaseTimeS = 0.0;
    m_phaseDurationS = kScript[m_phaseIndex].durationS;
    VehicleData *v = m_vehicle;

    // Reset everything that is phase specific.
    v->setLeftIndicator(false);
    v->setRightIndicator(false);
    v->setHazard(false);
    v->setHighBeam(false);
    v->setAbsWarning(false);
    v->setCheckEngine(false);
    m_sport = false;

    switch (kScript[m_phaseIndex].phase) {
    case Phase::EngineOff:
        m_engineOn = false;
        m_targetSpeed = 0.0;
        v->setGear(VehicleData::Park);
        v->setGearNumber(0);
        v->setParkingBrake(true);
        v->setDoorOpen(true);
        v->setSeatbeltWarning(true);
        v->setLowBeam(false);
        break;
    case Phase::Idle:
        m_engineOn = true;
        v->setDoorOpen(false);
        v->setLowBeam(true);
        break;
    case Phase::CityDrive:
        v->setParkingBrake(false);
        v->setSeatbeltWarning(false);
        v->setGear(VehicleData::Drive);
        m_targetSpeed = 62.0;
        m_accel = 9.0;
        break;
    case Phase::Cruise:
        m_targetSpeed = 118.0;
        m_accel = 7.0;
        break;
    case Phase::Slowdown:
        m_targetSpeed = 50.0;
        m_accel = 12.0;
        v->setRightIndicator(true);
        break;
    case Phase::SportRun:
        m_sport = true;
        v->setGear(VehicleData::Manual);
        m_targetSpeed = 195.0;
        m_accel = 20.0;
        break;
    case Phase::Braking:
        m_targetSpeed = 0.0;
        m_accel = 26.0;
        v->setGear(VehicleData::Drive);
        v->setAbsWarning(true);
        break;
    case Phase::HazardStop:
        m_targetSpeed = 0.0;
        v->setHazard(true);
        v->setGear(VehicleData::Neutral);
        v->setGearNumber(0);
        break;
    case Phase::Reverse:
        v->setGear(VehicleData::Reverse);
        v->setGearNumber(0);
        m_targetSpeed = 7.0;
        m_accel = 4.0;
        break;
    case Phase::Count:
        break;
    }
}

void VehicleSimulator::tick()
{
    const qint64 nowMs = m_clock.elapsed();
    const double dt = std::clamp((nowMs - m_lastMs) / 1000.0, 0.0, 0.25); // guard against stalls
    m_lastMs = nowMs;
    m_runTimeS += dt;
    m_phaseTimeS += dt;

    const auto phase = static_cast<Phase>(m_phaseIndex);

    // Timed events inside phases.
    if (phase == Phase::Idle && m_phaseTimeS > 1.5)
        m_vehicle->setSeatbeltWarning(false);
    if (phase == Phase::CityDrive)
        m_vehicle->setLeftIndicator(m_phaseTimeS < 3.5);
    if (phase == Phase::Cruise) {
        m_vehicle->setHighBeam(m_phaseTimeS > 2.0 && m_phaseTimeS < 8.0);
        m_vehicle->setCheckEngine(m_phaseTimeS > 4.0 && m_phaseTimeS < 7.0);
    }
    if (phase == Phase::Slowdown)
        m_vehicle->setRightIndicator(m_phaseTimeS < 4.0);
    if (phase == Phase::Braking)
        m_vehicle->setAbsWarning(m_phaseTimeS < 2.0);

    updateDriveTrain(dt);

    m_slowAccumS += dt;
    if (m_slowAccumS >= kSlowTickS) {
        slowTick(m_slowAccumS);
        m_slowAccumS = 0.0;
    }

    if (m_phaseTimeS >= m_phaseDurationS)
        enterPhase(m_phaseIndex + 1);
}

void VehicleSimulator::updateDriveTrain(double dt)
{
    // Speed approaches the target with a constant acceleration.
    const double delta = m_targetSpeed - m_speed;
    const double step = m_accel * dt;
    m_speed = std::abs(delta) <= step ? m_targetSpeed : m_speed + std::copysign(step, delta);
    m_speed = std::max(0.0, m_speed);

    double rpm = 0.0;
    const VehicleData::Gear selector = m_vehicle->gear();
    if (!m_engineOn) {
        rpm = 0.0;
        m_gear = 0;
    } else if (selector == VehicleData::Drive || selector == VehicleData::Manual) {
        if (m_gear < 1)
            m_gear = 1;
        const double upshiftRpm = m_sport ? 6350.0 : 2600.0;
        const double downshiftRpm = m_sport ? 3200.0 : 1250.0;
        if (m_gear < 6 && m_speed * kGearFactor[m_gear] > upshiftRpm)
            ++m_gear;
        else if (m_gear > 1 && m_speed * kGearFactor[m_gear] < downshiftRpm)
            --m_gear;
        rpm = std::max(kIdleRpm, m_speed * kGearFactor[m_gear]);
        m_vehicle->setGearNumber(m_gear);
    } else if (selector == VehicleData::Reverse) {
        rpm = kIdleRpm + m_speed * 110.0;
        m_gear = 0;
    } else {
        rpm = kIdleRpm;
        m_gear = 0;
    }
    if (rpm > 0.0)
        rpm += noise(15.0);

    m_vehicle->setSpeed(m_speed);
    m_vehicle->setRpm(rpm);

    const double km = m_speed * dt / 3600.0;
    m_odometer += km;
    m_tripA += km;
    m_tripB += km;
}

void VehicleSimulator::slowTick(double elapsedS)
{
    // Distances (only pushed once per second - plenty for the readouts).
    m_vehicle->setOdometer(m_odometer);
    m_vehicle->setTripA(m_tripA);
    m_vehicle->setTripB(m_tripB);

    // Fuel: idle consumption + speed dependent part; demo refill when empty.
    if (m_engineOn)
        m_fuel -= (0.02 + m_speed * 0.0005) * elapsedS;
    if (m_fuel < 6.0)
        m_fuel = 75.0;
    m_vehicle->setFuelLevel(m_fuel);
    m_vehicle->setRange(m_fuel / 100.0 * kTankLitres / kConsumptionL100 * 100.0);

    // Battery: alternator charging while running.
    const double volts = m_engineOn ? 14.1 + 0.15 * std::sin(m_runTimeS / 5.0) : 12.4;
    m_vehicle->setBatteryVoltage(volts + noise(0.03));
    m_vehicle->setBatteryWarning(!m_engineOn);
    m_vehicle->setOilPressureWarning(!m_engineOn);

    // Coolant: first-order approach to the thermostat (or hot sport) target.
    const double coolantTarget = !m_engineOn ? 22.0 : (m_sport ? 109.0 : 90.0);
    m_coolant += (coolantTarget - m_coolant) * std::min(1.0, 0.07 * elapsedS);
    m_vehicle->setCoolantTemperature(m_coolant);

    m_vehicle->setOutsideTemperature(21.5 + 1.5 * std::sin(m_runTimeS / 90.0));

    // Board sensor: slow sine through all zones (cold..critical), period 80 s.
    const double board = 45.0 + 33.0 * std::sin(2.0 * kPi * m_runTimeS / 80.0) + noise(0.4);
    m_temperature->setTemperature(board);
}

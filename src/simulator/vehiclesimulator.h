// VehicleSimulator - DEMO/TEST ONLY data source.
//
// Drives VehicleData and TemperatureProvider through their public setters with
// a scripted drive cycle so the dashboard looks alive on a dev machine.
// It is compiled only when the CMake option DASHBOARD_ENABLE_SIMULATOR is ON
// (default) and can additionally be disabled at runtime with --no-simulator
// or DASHBOARD_SIMULATOR=0. Production builds: -DDASHBOARD_ENABLE_SIMULATOR=OFF.

#pragma once

#include <QElapsedTimer>
#include <QObject>
#include <QTimer>

class VehicleData;
class TemperatureProvider;

class VehicleSimulator : public QObject
{
    Q_OBJECT

public:
    VehicleSimulator(VehicleData *vehicle, TemperatureProvider *temperature, QObject *parent = nullptr);

    void start();
    void stop();

private:
    enum class Phase { EngineOff, Idle, CityDrive, Cruise, Slowdown, SportRun, Braking, HazardStop, Reverse, Count };

    struct PhaseSpec {
        Phase phase;
        double durationS;
    };

    void tick();
    void slowTick(double elapsedS);
    void enterPhase(int index);
    void updateDriveTrain(double dt);

    VehicleData *m_vehicle;
    TemperatureProvider *m_temperature;
    QTimer m_timer;
    QElapsedTimer m_clock;
    qint64 m_lastMs = 0;
    double m_runTimeS = 0.0;
    double m_slowAccumS = 0.0;

    int m_phaseIndex = 0;
    double m_phaseTimeS = 0.0;
    double m_phaseDurationS = 0.0;
    double m_speed = 0.0;       // km/h
    double m_targetSpeed = 0.0; // km/h
    double m_accel = 0.0;       // km/h per second (magnitude)
    int m_gear = 0;             // 1..6 when moving
    bool m_sport = false;
    bool m_engineOn = false;

    double m_fuel = 31.0;       // % - starts lowish so the low-fuel state shows up
    double m_coolant = 24.0;
    double m_odometer = 48213.4;
    double m_tripA = 312.7;
    double m_tripB = 27.9;
};

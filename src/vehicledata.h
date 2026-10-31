// VehicleData - single source of truth for every value shown on the cluster.
//
// The QML UI only *reads* these properties (bindings). Data sources - the demo
// simulator today, CAN/LIN/sensor readers tomorrow - *write* them through the
// public setter slots. All setters must be called from the GUI thread; from a
// worker thread use a queued connection or QMetaObject::invokeMethod().
//
// Units are always metric/SI internally (km/h, km, degC, V, %). Conversion to
// mph / miles / degF is a presentation concern and happens in QML (Theme).

#pragma once

#include <QObject>
#include <QtQml/qqmlregistration.h>

class QQmlEngine;
class QJSEngine;

class VehicleData : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    // Driving
    Q_PROPERTY(double speed READ speed WRITE setSpeed NOTIFY speedChanged)                  // km/h
    Q_PROPERTY(double rpm READ rpm WRITE setRpm NOTIFY rpmChanged)                          // 1/min
    Q_PROPERTY(Gear gear READ gear WRITE setGear NOTIFY gearChanged)
    Q_PROPERTY(int gearNumber READ gearNumber WRITE setGearNumber NOTIFY gearNumberChanged) // 0 = none

    // Secondary gauges
    Q_PROPERTY(double fuelLevel READ fuelLevel WRITE setFuelLevel NOTIFY fuelLevelChanged)                  // 0..100 %
    Q_PROPERTY(double batteryVoltage READ batteryVoltage WRITE setBatteryVoltage NOTIFY batteryVoltageChanged) // V
    Q_PROPERTY(double coolantTemperature READ coolantTemperature WRITE setCoolantTemperature NOTIFY coolantTemperatureChanged) // degC
    Q_PROPERTY(double outsideTemperature READ outsideTemperature WRITE setOutsideTemperature NOTIFY outsideTemperatureChanged) // degC

    // Distances
    Q_PROPERTY(double odometer READ odometer WRITE setOdometer NOTIFY odometerChanged) // km
    Q_PROPERTY(double tripA READ tripA WRITE setTripA NOTIFY tripAChanged)             // km
    Q_PROPERTY(double tripB READ tripB WRITE setTripB NOTIFY tripBChanged)             // km
    Q_PROPERTY(double range READ range WRITE setRange NOTIFY rangeChanged)             // km

    // Indicators
    Q_PROPERTY(bool leftIndicator READ leftIndicator WRITE setLeftIndicator NOTIFY leftIndicatorChanged)
    Q_PROPERTY(bool rightIndicator READ rightIndicator WRITE setRightIndicator NOTIFY rightIndicatorChanged)
    Q_PROPERTY(bool hazard READ hazard WRITE setHazard NOTIFY hazardChanged)

    // Telltales
    Q_PROPERTY(bool checkEngine READ checkEngine WRITE setCheckEngine NOTIFY checkEngineChanged)
    Q_PROPERTY(bool oilPressureWarning READ oilPressureWarning WRITE setOilPressureWarning NOTIFY oilPressureWarningChanged)
    Q_PROPERTY(bool batteryWarning READ batteryWarning WRITE setBatteryWarning NOTIFY batteryWarningChanged)
    Q_PROPERTY(bool absWarning READ absWarning WRITE setAbsWarning NOTIFY absWarningChanged)
    Q_PROPERTY(bool seatbeltWarning READ seatbeltWarning WRITE setSeatbeltWarning NOTIFY seatbeltWarningChanged)
    Q_PROPERTY(bool parkingBrake READ parkingBrake WRITE setParkingBrake NOTIFY parkingBrakeChanged)
    Q_PROPERTY(bool highBeam READ highBeam WRITE setHighBeam NOTIFY highBeamChanged)
    Q_PROPERTY(bool lowBeam READ lowBeam WRITE setLowBeam NOTIFY lowBeamChanged)
    Q_PROPERTY(bool doorOpen READ doorOpen WRITE setDoorOpen NOTIFY doorOpenChanged)

public:
    enum Gear { Park = 0, Reverse, Neutral, Drive, Manual };
    Q_ENUM(Gear)

    // Deliberately NOT default-constructible: otherwise QML would create its
    // own (empty) instance instead of calling create() below.
    explicit VehicleData(QObject *parent);
    ~VehicleData() override;

    // The C++ side owns the single instance (created in main()); QML gets the
    // very same object through this factory.
    static VehicleData *create(QQmlEngine *qmlEngine, QJSEngine *jsEngine);
    static VehicleData *instance();

    double speed() const { return m_speed; }
    double rpm() const { return m_rpm; }
    Gear gear() const { return m_gear; }
    int gearNumber() const { return m_gearNumber; }
    double fuelLevel() const { return m_fuelLevel; }
    double batteryVoltage() const { return m_batteryVoltage; }
    double coolantTemperature() const { return m_coolantTemperature; }
    double outsideTemperature() const { return m_outsideTemperature; }
    double odometer() const { return m_odometer; }
    double tripA() const { return m_tripA; }
    double tripB() const { return m_tripB; }
    double range() const { return m_range; }
    bool leftIndicator() const { return m_leftIndicator; }
    bool rightIndicator() const { return m_rightIndicator; }
    bool hazard() const { return m_hazard; }
    bool checkEngine() const { return m_checkEngine; }
    bool oilPressureWarning() const { return m_oilPressureWarning; }
    bool batteryWarning() const { return m_batteryWarning; }
    bool absWarning() const { return m_absWarning; }
    bool seatbeltWarning() const { return m_seatbeltWarning; }
    bool parkingBrake() const { return m_parkingBrake; }
    bool highBeam() const { return m_highBeam; }
    bool lowBeam() const { return m_lowBeam; }
    bool doorOpen() const { return m_doorOpen; }

    Q_INVOKABLE void resetTripA();
    Q_INVOKABLE void resetTripB();

public slots:
    void setSpeed(double kmh);
    void setRpm(double rpm);
    void setGear(VehicleData::Gear gear);
    void setGearNumber(int gearNumber);
    void setFuelLevel(double percent);
    void setBatteryVoltage(double volts);
    void setCoolantTemperature(double celsius);
    void setOutsideTemperature(double celsius);
    void setOdometer(double km);
    void setTripA(double km);
    void setTripB(double km);
    void setRange(double km);
    void setLeftIndicator(bool on);
    void setRightIndicator(bool on);
    void setHazard(bool on);
    void setCheckEngine(bool on);
    void setOilPressureWarning(bool on);
    void setBatteryWarning(bool on);
    void setAbsWarning(bool on);
    void setSeatbeltWarning(bool on);
    void setParkingBrake(bool on);
    void setHighBeam(bool on);
    void setLowBeam(bool on);
    void setDoorOpen(bool on);

signals:
    void speedChanged();
    void rpmChanged();
    void gearChanged();
    void gearNumberChanged();
    void fuelLevelChanged();
    void batteryVoltageChanged();
    void coolantTemperatureChanged();
    void outsideTemperatureChanged();
    void odometerChanged();
    void tripAChanged();
    void tripBChanged();
    void rangeChanged();
    void leftIndicatorChanged();
    void rightIndicatorChanged();
    void hazardChanged();
    void checkEngineChanged();
    void oilPressureWarningChanged();
    void batteryWarningChanged();
    void absWarningChanged();
    void seatbeltWarningChanged();
    void parkingBrakeChanged();
    void highBeamChanged();
    void lowBeamChanged();
    void doorOpenChanged();

private:
    // Assigns and emits only on a real change, so QML bindings are not
    // re-evaluated for repeated identical samples (saves CPU on embedded).
    template<typename T>
    void assign(T &member, T value, void (VehicleData::*notify)());
    void assign(double &member, double value, double epsilon, void (VehicleData::*notify)());

    double m_speed = 0.0;
    double m_rpm = 0.0;
    Gear m_gear = Park;
    int m_gearNumber = 0;
    double m_fuelLevel = 0.0;
    double m_batteryVoltage = 0.0;
    double m_coolantTemperature = 0.0;
    double m_outsideTemperature = 0.0;
    double m_odometer = 0.0;
    double m_tripA = 0.0;
    double m_tripB = 0.0;
    double m_range = 0.0;
    bool m_leftIndicator = false;
    bool m_rightIndicator = false;
    bool m_hazard = false;
    bool m_checkEngine = false;
    bool m_oilPressureWarning = false;
    bool m_batteryWarning = false;
    bool m_absWarning = false;
    bool m_seatbeltWarning = false;
    bool m_parkingBrake = false;
    bool m_highBeam = false;
    bool m_lowBeam = false;
    bool m_doorOpen = false;
};

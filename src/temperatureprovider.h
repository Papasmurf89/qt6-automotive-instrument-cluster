// TemperatureProvider - backend for the board temperature sensor shown by
// TemperatureWidget.qml.
//
// The widget only binds to `temperature` and `valid`. How the value is
// obtained is deliberately NOT implemented here. There are two ways to plug in
// the real sensor (see README.md, "Connecting real data"):
//
//   A) PUSH: from your own code (any thread) call
//          TemperatureProvider::instance()->setTemperature(celsius);
//      setTemperature() is thread-safe; it re-posts itself to the GUI thread.
//
//   B) PULL: implement TemperatureProvider::readSensor() in
//      temperatureprovider.cpp. It is polled by startPolling(), which main()
//      calls whenever the demo simulator is not running.
//
// If no value arrives for staleTimeoutMs, `valid` goes false and the widget
// shows "--" instead of a frozen, possibly wrong number.

#pragma once

#include <QObject>
#include <QTimer>
#include <QtQml/qqmlregistration.h>

#include <optional>

class QQmlEngine;
class QJSEngine;

class TemperatureProvider : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    /// Latest sensor value in degrees Celsius (meaningful only while `valid`).
    Q_PROPERTY(double temperature READ temperature WRITE setTemperature NOTIFY temperatureChanged)
    /// False until the first sample arrives, and again when samples go stale.
    Q_PROPERTY(bool valid READ isValid NOTIFY validChanged)
    /// Mark the reading invalid if no new sample arrives within this time.
    Q_PROPERTY(int staleTimeoutMs READ staleTimeoutMs WRITE setStaleTimeoutMs NOTIFY staleTimeoutMsChanged)

public:
    // Deliberately NOT default-constructible: otherwise QML would create its
    // own (empty) instance instead of calling create() below.
    explicit TemperatureProvider(QObject *parent);
    ~TemperatureProvider() override;

    static TemperatureProvider *create(QQmlEngine *qmlEngine, QJSEngine *jsEngine);
    static TemperatureProvider *instance();

    double temperature() const { return m_temperature; }
    bool isValid() const { return m_valid; }
    int staleTimeoutMs() const { return m_staleTimer.interval(); }
    void setStaleTimeoutMs(int ms);

    /// Periodically calls readSensor() (PULL integration). No-op until
    /// readSensor() is implemented, apart from one cheap timer tick.
    void startPolling(int intervalMs = 1000);
    void stopPolling();

public slots:
    /// PUSH integration: thread-safe, value in degrees Celsius.
    /// Non-finite values (NaN/inf) are treated as a sensor fault -> invalid.
    void setTemperature(double celsius);
    /// Report a sensor fault (e.g. read error); the widget shows "--".
    void invalidate();

signals:
    void temperatureChanged();
    void validChanged();
    void staleTimeoutMsChanged();

private:
    /// PULL integration point - see temperatureprovider.cpp.
    std::optional<double> readSensor();
    void poll();
    void setValid(bool valid);

    double m_temperature = 0.0;
    bool m_valid = false;
    QTimer m_pollTimer;
    QTimer m_staleTimer;
};

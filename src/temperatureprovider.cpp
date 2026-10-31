#include "temperatureprovider.h"

#include <QJSEngine>
#include <QLoggingCategory>
#include <QQmlEngine>
#include <QThread>

#include <cmath>

Q_LOGGING_CATEGORY(lcTemp, "dashboard.temperature")

namespace {
TemperatureProvider *s_instance = nullptr;
constexpr int kDefaultStaleTimeoutMs = 5000;
} // namespace

TemperatureProvider::TemperatureProvider(QObject *parent)
    : QObject(parent)
{
    if (s_instance)
        qFatal("TemperatureProvider: only one instance may exist");
    s_instance = this;

    m_pollTimer.setTimerType(Qt::CoarseTimer);
    connect(&m_pollTimer, &QTimer::timeout, this, &TemperatureProvider::poll);

    m_staleTimer.setSingleShot(true);
    m_staleTimer.setInterval(kDefaultStaleTimeoutMs);
    connect(&m_staleTimer, &QTimer::timeout, this, [this] {
        qCWarning(lcTemp) << "no temperature sample for" << m_staleTimer.interval() << "ms - marking invalid";
        setValid(false);
    });
}

TemperatureProvider::~TemperatureProvider()
{
    if (s_instance == this)
        s_instance = nullptr;
}

TemperatureProvider *TemperatureProvider::create(QQmlEngine *qmlEngine, QJSEngine *jsEngine)
{
    Q_UNUSED(qmlEngine)
    if (!s_instance)
        qFatal("TemperatureProvider::create: instantiate TemperatureProvider in main() before loading QML");
    Q_ASSERT(jsEngine->thread() == s_instance->thread());
    QJSEngine::setObjectOwnership(s_instance, QJSEngine::CppOwnership);
    return s_instance;
}

TemperatureProvider *TemperatureProvider::instance()
{
    return s_instance;
}

void TemperatureProvider::setStaleTimeoutMs(int ms)
{
    if (ms == m_staleTimer.interval())
        return;
    m_staleTimer.setInterval(ms);
    emit staleTimeoutMsChanged();
}

void TemperatureProvider::startPolling(int intervalMs)
{
    m_pollTimer.start(intervalMs);
}

void TemperatureProvider::stopPolling()
{
    m_pollTimer.stop();
}

void TemperatureProvider::setTemperature(double celsius)
{
    // Allow calls from a sensor thread: hop to the thread owning this object.
    if (QThread::currentThread() != thread()) {
        QMetaObject::invokeMethod(this, [this, celsius] { setTemperature(celsius); }, Qt::QueuedConnection);
        return;
    }

    if (!std::isfinite(celsius)) {
        invalidate();
        return;
    }

    if (m_staleTimer.interval() > 0)
        m_staleTimer.start(); // restart watchdog

    if (!qFuzzyCompare(1.0 + m_temperature, 1.0 + celsius)) {
        m_temperature = celsius;
        emit temperatureChanged();
    }
    setValid(true);
}

void TemperatureProvider::invalidate()
{
    if (QThread::currentThread() != thread()) {
        QMetaObject::invokeMethod(this, &TemperatureProvider::invalidate, Qt::QueuedConnection);
        return;
    }
    m_staleTimer.stop();
    setValid(false);
}

void TemperatureProvider::setValid(bool valid)
{
    if (m_valid == valid)
        return;
    m_valid = valid;
    emit validChanged();
}

void TemperatureProvider::poll()
{
    if (const std::optional<double> value = readSensor())
        setTemperature(*value);
}

// ============================================================================
// >>>>>>>>>>>>>>>>>>>>>>>>  SENSOR INTEGRATION POINT  <<<<<<<<<<<<<<<<<<<<<<<<<
// ============================================================================
// Return the current board temperature in degrees Celsius, or std::nullopt if
// no reading is available right now (the widget then keeps the last value
// until staleTimeoutMs expires, after which it shows "--").
//
// Called on the GUI thread every `intervalMs` (see startPolling() in main.cpp),
// so it must be fast and non-blocking (a sysfs/hwmon read is fine; a slow I2C
// transaction with retries belongs in a worker thread that uses the PUSH path,
// i.e. calls setTemperature() itself).
//
// Example (hwmon/thermal sysfs - adapt the path to your board):
//
//     QFile f(QStringLiteral("/sys/class/thermal/thermal_zone0/temp"));
//     if (!f.open(QIODevice::ReadOnly))
//         return std::nullopt;
//     bool ok = false;
//     const double milliCelsius = f.readAll().trimmed().toDouble(&ok);
//     return ok ? std::optional<double>(milliCelsius / 1000.0) : std::nullopt;
//
std::optional<double> TemperatureProvider::readSensor()
{
    return std::nullopt; // TODO(sensor): not implemented yet - no sensor access by design.
}
// ============================================================================

// Instrument cluster entry point.
//
// Nothing about the windowing system or renderer is hard-coded: the Qt
// platform plugin comes from QT_QPA_PLATFORM (e.g. "wayland" under Weston)
// and the scene graph backend from QT_QUICK_BACKEND (unset = GPU/RHI,
// "software" = CPU raster).

#include "temperatureprovider.h"
#include "vehicledata.h"

#ifdef DASHBOARD_ENABLE_SIMULATOR
#include "simulator/vehiclesimulator.h"
#endif

#include <QCommandLineParser>
#include <QGuiApplication>
#include <QImage>
#include <QLoggingCategory>
#include <QQmlApplicationEngine>
#include <QQuickWindow>
#include <QTimer>

#include <memory>

Q_LOGGING_CATEGORY(lcMain, "dashboard")

namespace {
bool envFlag(const char *name, bool defaultValue)
{
    if (!qEnvironmentVariableIsSet(name))
        return defaultValue;
    const QByteArray v = qgetenv(name).trimmed().toLower();
    return !(v == "0" || v == "false" || v == "no" || v == "off");
}
} // namespace

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    QGuiApplication::setApplicationName(QStringLiteral("dashboard"));
    QGuiApplication::setApplicationVersion(QStringLiteral(DASHBOARD_VERSION));
    QGuiApplication::setDesktopFileName(QStringLiteral("dashboard")); // Wayland app_id

    QCommandLineParser parser;
    parser.setApplicationDescription(QStringLiteral("Qt Quick instrument cluster"));
    parser.addHelpOption();
    parser.addVersionOption();
    const QCommandLineOption windowedOpt(QStringLiteral("windowed"),
        QStringLiteral("Show a normal window instead of fullscreen (env DASHBOARD_WINDOWED=1)."));
    const QCommandLineOption noSimOpt(QStringLiteral("no-simulator"),
        QStringLiteral("Do not start the demo data simulator (env DASHBOARD_SIMULATOR=0)."));
    const QCommandLineOption shotOpt(QStringLiteral("screenshot"),
        QStringLiteral("Save a screenshot of the window to <file> (testing aid)."), QStringLiteral("file"));
    const QCommandLineOption shotDelayOpt(QStringLiteral("screenshot-delay"),
        QStringLiteral("Delay before the screenshot in ms (default 3000)."), QStringLiteral("ms"), QStringLiteral("3000"));
    const QCommandLineOption quitAfterOpt(QStringLiteral("quit-after"),
        QStringLiteral("Quit automatically after <ms> (smoke tests)."), QStringLiteral("ms"));
    // Read directly by Theme.qml (Qt.application.arguments); declared here so
    // the parser accepts them and lists them in --help.
    const QCommandLineOption dayOpt(QStringLiteral("day"), QStringLiteral("Start with the day theme."));
    const QCommandLineOption imperialOpt(QStringLiteral("imperial"), QStringLiteral("Start with mph / miles / degF."));
    parser.addOptions({windowedOpt, noSimOpt, shotOpt, shotDelayOpt, quitAfterOpt, dayOpt, imperialOpt});
    parser.process(app);

    const bool windowed = parser.isSet(windowedOpt) || envFlag("DASHBOARD_WINDOWED", false);

    // Backend objects live for the whole program and outlive the QML engine.
    VehicleData vehicleData(nullptr);
    TemperatureProvider temperatureProvider(nullptr);

    bool simulatorRunning = false;
#ifdef DASHBOARD_ENABLE_SIMULATOR
    std::unique_ptr<VehicleSimulator> simulator;
    if (!parser.isSet(noSimOpt) && envFlag("DASHBOARD_SIMULATOR", true)) {
        simulator = std::make_unique<VehicleSimulator>(&vehicleData, &temperatureProvider);
        simulator->start();
        simulatorRunning = true;
    }
#endif
    if (!simulatorRunning) {
        // Real data path: poll the board sensor (see TemperatureProvider::readSensor()).
        temperatureProvider.startPolling(1000);
    }
    qCInfo(lcMain) << "simulator:" << (simulatorRunning ? "on" : "off");

    QQmlApplicationEngine engine;
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed, &app,
                     [] { QCoreApplication::exit(EXIT_FAILURE); }, Qt::QueuedConnection);
    engine.loadFromModule("Dashboard", "Main");
    if (engine.rootObjects().isEmpty())
        return EXIT_FAILURE;

    auto *window = qobject_cast<QQuickWindow *>(engine.rootObjects().constFirst());
    if (!window) {
        qCCritical(lcMain) << "root QML object is not a Window";
        return EXIT_FAILURE;
    }

    // Under Weston this requests xdg-shell fullscreen; the compositor then
    // resizes the window and the QML layout follows via anchors.
    if (windowed)
        window->show();
    else
        window->showFullScreen();

    QObject::connect(window, &QQuickWindow::sceneGraphInitialized, window, [window] {
        qCInfo(lcMain) << "platform:" << QGuiApplication::platformName()
                       << "| scene graph backend:" << (QQuickWindow::sceneGraphBackend().isEmpty()
                                                           ? QStringLiteral("default (rhi)")
                                                           : QQuickWindow::sceneGraphBackend())
                       << "| graphics api:" << window->rendererInterface()->graphicsApi();
    }, Qt::DirectConnection);

    if (parser.isSet(shotOpt)) {
        const QString file = parser.value(shotOpt);
        QTimer::singleShot(parser.value(shotDelayOpt).toInt(), window, [window, file] {
            const QImage image = window->grabWindow();
            if (image.isNull() || !image.save(file))
                qCWarning(lcMain) << "screenshot failed:" << file;
            else
                qCInfo(lcMain) << "screenshot saved:" << file << image.size();
        });
    }
    if (parser.isSet(quitAfterOpt))
        QTimer::singleShot(parser.value(quitAfterOpt).toInt(), &app, &QCoreApplication::quit);

    return app.exec();
}

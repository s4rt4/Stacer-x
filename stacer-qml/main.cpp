#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QIcon>

#include "SystemController.h"
#include "ProcessesController.h"
#include "ServicesController.h"
#include "StartupController.h"
#include "CleanerController.h"
#include "ResourcesController.h"
#include "SettingsController.h"
#include "UninstallerController.h"
#include "HostsController.h"

int main(int argc, char *argv[])
{
    qputenv("QT_ENABLE_HIGHDPI_SCALING", QByteArray("1"));
    QGuiApplication app(argc, argv);

    // Fully custom look — keep the controls neutral so our styling wins.
    QQuickStyle::setStyle("Basic");

    app.setApplicationName("stacer-x");
    app.setApplicationDisplayName("Stacer-X");
    app.setApplicationVersion("1.7.0");
    app.setOrganizationName("stacer");   // for QSettings location
    app.setOrganizationDomain("stacer.x");
    app.setWindowIcon(QIcon(QStringLiteral(":/qt/qml/Stacer/qml/stacer-logo.svg")));
    // Associate the window with the stacer-x.desktop entry so the GNOME/KDE
    // dock and app launcher show the brand logo (Wayland uses this as app_id).
    QGuiApplication::setDesktopFileName(QStringLiteral("stacer-x"));

    SystemController systemController;
    ProcessesController processesController;
    ServicesController servicesController;
    StartupController startupController;
    CleanerController cleanerController;
    ResourcesController resourcesController;
    SettingsController settingsController;
    UninstallerController uninstallerController;
    HostsController hostsController;

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("system", &systemController);
    engine.rootContext()->setContextProperty("processes", &processesController);
    engine.rootContext()->setContextProperty("services", &servicesController);
    engine.rootContext()->setContextProperty("startup", &startupController);
    engine.rootContext()->setContextProperty("cleaner", &cleanerController);
    // NOTE: not "resources" — that name shadows Item.resources in QML.
    engine.rootContext()->setContextProperty("resmon", &resourcesController);
    engine.rootContext()->setContextProperty("settings", &settingsController);
    engine.rootContext()->setContextProperty("uninstaller", &uninstallerController);
    engine.rootContext()->setContextProperty("hosts", &hostsController);

    QObject::connect(
        &engine, &QQmlApplicationEngine::objectCreationFailed, &app,
        []() { QCoreApplication::exit(-1); }, Qt::QueuedConnection);

    engine.loadFromModule("Stacer", "Main");

    if (engine.rootObjects().isEmpty())
        return -1;

    return app.exec();
}

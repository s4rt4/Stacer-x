#include "SettingsController.h"

#include <QCoreApplication>
#include <QDir>
#include <QFile>
#include <QStandardPaths>

SettingsController::SettingsController(QObject *parent) : QObject(parent)
{
}

QString SettingsController::autostartFilePath() const
{
    return QStandardPaths::writableLocation(QStandardPaths::ConfigLocation)
           + "/autostart/stacer-x.desktop";
}

QString SettingsController::configPath() const
{
    return QStandardPaths::writableLocation(QStandardPaths::AppConfigLocation);
}

bool SettingsController::startOnLogin() const
{
    return QFile::exists(autostartFilePath());
}

void SettingsController::setStartOnLogin(bool on)
{
    if (on == startOnLogin())
        return;

    const QString path = autostartFilePath();

    if (on) {
        QDir().mkpath(QFileInfo(path).absolutePath());

        const QString exec = QCoreApplication::applicationFilePath();
        const QString content =
            "[Desktop Entry]\n"
            "Type=Application\n"
            "Name=Stacer-X\n"
            "Comment=Linux system optimizer\n"
            "Exec=" + exec + "\n"
            "Icon=stacer-x\n"
            "Terminal=false\n"
            "X-GNOME-Autostart-enabled=true\n";

        QFile file(path);
        if (file.open(QIODevice::WriteOnly | QIODevice::Truncate | QIODevice::Text)) {
            file.write(content.toUtf8());
            file.close();
        }
    } else {
        QFile::remove(path);
    }

    emit startOnLoginChanged();
}

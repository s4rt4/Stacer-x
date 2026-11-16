#include "SettingsController.h"

#include <QCoreApplication>
#include <QDir>
#include <QFile>
#include <QLocale>
#include <QSettings>
#include <QStandardPaths>

SettingsController::SettingsController(QObject *parent) : QObject(parent)
{
}

QString SettingsController::language() const
{
    const QString fallback = QLocale::system().language() == QLocale::Chinese
                                 ? QStringLiteral("zh_CN") : QStringLiteral("en");
    const QString saved = QSettings().value(QStringLiteral("ui/language"), fallback).toString();
    return saved == QLatin1String("zh_CN") ? QStringLiteral("zh_CN") : QStringLiteral("en");
}

void SettingsController::setLanguage(const QString &language)
{
    if ((language != QLatin1String("zh_CN") && language != QLatin1String("en"))
        || language == this->language())
        return;
    QSettings().setValue(QStringLiteral("ui/language"), language);
    emit languageChanged();
}

bool SettingsController::closeToTray() const
{
    return QSettings().value(QStringLiteral("ui/closeToTray"), true).toBool();
}

void SettingsController::setCloseToTray(bool enabled)
{
    if (enabled == closeToTray())
        return;
    QSettings().setValue(QStringLiteral("ui/closeToTray"), enabled);
    emit closeToTrayChanged();
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

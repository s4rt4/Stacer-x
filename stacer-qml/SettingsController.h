#ifndef SETTINGSCONTROLLER_H
#define SETTINGSCONTROLLER_H

#include <QObject>
#include <QString>

// App preferences exposed to QML as `settings`. Currently: launch Stacer on
// login by managing an autostart .desktop entry (user-level, no elevation).
class SettingsController : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool startOnLogin READ startOnLogin WRITE setStartOnLogin NOTIFY startOnLoginChanged)
    Q_PROPERTY(QString accentHex READ accentHex CONSTANT)
    Q_PROPERTY(QString configPath READ configPath CONSTANT)

  public:
    explicit SettingsController(QObject *parent = nullptr);

    bool startOnLogin() const;
    void setStartOnLogin(bool on);

    QString accentHex() const { return QStringLiteral("#5cc4ef"); }
    QString configPath() const;

  signals:
    void startOnLoginChanged();

  private:
    QString autostartFilePath() const;
};

#endif // SETTINGSCONTROLLER_H

#include "StartupController.h"

#include <algorithm>

#include <QDir>
#include <QFile>
#include <QStandardPaths>

// Read a "Key=value" line from a .desktop file's lines (exact key match).
static QString desktopValue(const QStringList &lines, const QString &key)
{
    const QString prefix = key + "=";
    for (const QString &line : lines) {
        if (line.startsWith(prefix))
            return line.mid(prefix.size()).trimmed();
    }
    return QString();
}

static QStringList readLines(const QString &path)
{
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text))
        return {};
    return QString::fromUtf8(file.readAll()).split('\n');
}

StartupController::StartupController(QObject *parent) : QAbstractListModel(parent)
{
    mAutostartPath =
        QStandardPaths::writableLocation(QStandardPaths::ConfigLocation) + "/autostart";

    if (!QDir(mAutostartPath).exists())
        QDir().mkpath(mAutostartPath);

    mWatcher.addPath(mAutostartPath);
    connect(&mWatcher, &QFileSystemWatcher::directoryChanged, this, [this]() { reload(); });
}

int StartupController::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid())
        return 0;
    return mRows.size();
}

QVariant StartupController::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= mRows.size())
        return QVariant();

    const Entry &e = mRows.at(index.row());
    switch (role) {
        case NameRole:    return e.name;
        case EnabledRole: return e.enabled;
        case PathRole:    return e.path;
    }
    return QVariant();
}

QHash<int, QByteArray> StartupController::roleNames() const
{
    return {
        { NameRole,    "name" },
        { EnabledRole, "enabled" },
        { PathRole,    "path" },
    };
}

void StartupController::setActive(bool active)
{
    if (active)
        reload();
}

void StartupController::reload()
{
    QList<Entry> entries;

    QDir dir(mAutostartPath, "*.desktop");
    const QFileInfoList files = dir.entryInfoList(QDir::Files);
    for (const QFileInfo &info : files) {
        const QStringList lines = readLines(info.absoluteFilePath());

        const QString name = desktopValue(lines, "Name");
        if (name.isEmpty())
            continue;

        const QString hidden = desktopValue(lines, "Hidden").toLower();
        const QString gnome = desktopValue(lines, "X-GNOME-Autostart-enabled").toLower();

        bool enabled;
        if (!hidden.isEmpty())
            enabled = (hidden != "true");   // Hidden=true means disabled
        else if (!gnome.isEmpty())
            enabled = (gnome == "true");
        else
            enabled = true;

        entries.append({ name, enabled, info.absoluteFilePath() });
    }

    std::sort(entries.begin(), entries.end(),
              [](const Entry &a, const Entry &b) { return a.name.toLower() < b.name.toLower(); });

    beginResetModel();
    mRows = entries;
    endResetModel();
    emit countChanged();
}

void StartupController::setEnabled(const QString &path, bool enabled)
{
    QStringList lines = readLines(path);
    if (lines.isEmpty())
        return;

    // Mirror legacy logic: prefer Hidden=, else X-GNOME-Autostart-enabled=.
    bool written = false;
    for (int i = 0; i < lines.size(); ++i) {
        if (lines.at(i).startsWith("Hidden=")) {
            lines[i] = QString("Hidden=%1").arg(enabled ? "false" : "true");
            written = true;
            break;
        }
    }
    if (!written) {
        for (int i = 0; i < lines.size(); ++i) {
            if (lines.at(i).startsWith("X-GNOME-Autostart-enabled=")) {
                lines[i] = QString("X-GNOME-Autostart-enabled=%1").arg(enabled ? "true" : "false");
                written = true;
                break;
            }
        }
    }
    if (!written)
        lines.append(QString("Hidden=%1").arg(enabled ? "false" : "true"));

    QFile file(path);
    if (file.open(QIODevice::WriteOnly | QIODevice::Truncate | QIODevice::Text)) {
        QString out = lines.join('\n');
        if (!out.endsWith('\n'))
            out.append('\n');
        file.write(out.toUtf8());
        file.close();
    }

    reload();
}

void StartupController::removeApp(const QString &path)
{
    if (QFile::remove(path))
        reload();
}

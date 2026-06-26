#include "HostsController.h"

#include <QDir>
#include <QFile>
#include <QRegularExpression>
#include <QtConcurrent>

#include "Utils/command_util.h"

namespace {
const char *kHostsPath = "/etc/hosts";

// A host line is "<ip> <hostname...>", optionally prefixed by "# " (disabled).
bool looksLikeIp(const QString &token)
{
    static const QRegularExpression re("^[0-9a-fA-F:.]+$");
    return (token.contains('.') || token.contains(':')) && re.match(token).hasMatch();
}
} // namespace

HostsController::HostsController(QObject *parent) : QAbstractListModel(parent)
{
}

int HostsController::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid())
        return 0;
    return mEntries.size();
}

QVariant HostsController::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= mEntries.size())
        return QVariant();

    const Entry &e = mEntries.at(index.row());
    switch (role) {
        case IpRole:      return e.ip;
        case HostRole:    return e.host;
        case EnabledRole: return e.enabled;
    }
    return QVariant();
}

QHash<int, QByteArray> HostsController::roleNames() const
{
    return {
        { IpRole,      "ip" },
        { HostRole,    "host" },
        { EnabledRole, "enabled" },
    };
}

void HostsController::setActive(bool active)
{
    if (active && !mLoaded)
        reload();
}

void HostsController::reload()
{
    mLines.clear();

    QFile file(kHostsPath);
    if (file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        const QString content = QString::fromUtf8(file.readAll());
        mLines = content.split('\n');
        // Drop a trailing empty element from a final newline.
        if (!mLines.isEmpty() && mLines.last().isEmpty())
            mLines.removeLast();
    }
    mLoaded = true;
    parse();
}

void HostsController::parse()
{
    QList<Entry> entries;

    for (int i = 0; i < mLines.size(); ++i) {
        QString line = mLines.at(i).trimmed();
        if (line.isEmpty())
            continue;

        bool enabled = true;
        if (line.startsWith('#')) {
            enabled = false;
            line = line.mid(1).trimmed();
        }

        const QStringList parts = line.split(QRegularExpression("\\s+"), Qt::SkipEmptyParts);
        if (parts.size() < 2 || !looksLikeIp(parts.first()))
            continue;   // plain comment or malformed — keep in mLines, not an entry

        Entry e;
        e.lineIndex = i;
        e.ip = parts.first();
        e.host = QStringList(parts.mid(1)).join(' ');
        e.enabled = enabled;
        entries.append(e);
    }

    beginResetModel();
    mEntries = entries;
    endResetModel();
    emit countChanged();
}

void HostsController::setBusy(bool busy)
{
    if (mBusy == busy)
        return;
    mBusy = busy;
    emit busyChanged();
}

void HostsController::writeAndReload(const QStringList &lines)
{
    if (mBusy)
        return;
    setBusy(true);

    const QString content = lines.join('\n') + '\n';

    (void) QtConcurrent::run([this, content]() {
        // Stage to a user temp file, then copy into place with elevation.
        const QString tmp = QDir::tempPath() + "/stacer-x-hosts.tmp";
        QFile f(tmp);
        if (f.open(QIODevice::WriteOnly | QIODevice::Truncate | QIODevice::Text)) {
            f.write(content.toUtf8());
            f.close();
            try {
                CommandUtil::sudoExec("cp", { tmp, kHostsPath });
            } catch (const QString &ex) {
                qCritical() << ex;
            }
            QFile::remove(tmp);
        }

        QMetaObject::invokeMethod(
            this,
            [this]() {
                setBusy(false);
                reload();
            },
            Qt::QueuedConnection);
    });
}

void HostsController::toggle(int index)
{
    if (index < 0 || index >= mEntries.size())
        return;

    const Entry &e = mEntries.at(index);
    QStringList lines = mLines;
    QString line = lines.at(e.lineIndex);

    if (e.enabled) {
        line = "# " + line.trimmed();
    } else {
        QString t = line.trimmed();
        if (t.startsWith('#'))
            t = t.mid(1).trimmed();
        line = t;
    }
    lines[e.lineIndex] = line;
    writeAndReload(lines);
}

void HostsController::removeEntry(int index)
{
    if (index < 0 || index >= mEntries.size())
        return;

    QStringList lines = mLines;
    lines.removeAt(mEntries.at(index).lineIndex);
    writeAndReload(lines);
}

void HostsController::addEntry(const QString &ip, const QString &hostname)
{
    const QString i = ip.trimmed();
    const QString h = hostname.trimmed();
    if (i.isEmpty() || h.isEmpty())
        return;

    QStringList lines = mLines;
    lines.append(i + "\t" + h);
    writeAndReload(lines);
}

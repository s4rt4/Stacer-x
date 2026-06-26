#include "CleanerController.h"

#include <utility>

#include <QDir>
#include <QDirIterator>
#include <QFile>
#include <QFileInfoList>
#include <QVariantMap>
#include <QtConcurrent>

#include "Info/system_info.h"
#include "Tools/package_tool.h"
#include "Utils/command_util.h"
#include "Utils/format_util.h"

namespace {

QString trashPath()
{
    return QDir::homePath() + "/.local/share/Trash";
}

// Package-manager cache directories for the current distro.
QStringList packageCacheDirs()
{
    QStringList candidates;
    switch (PackageTool::currentPackageTool) {
        case PackageTool::DNF:
        case PackageTool::YUM:
            candidates << "/var/cache/dnf" << "/var/cache/libdnf5" << "/var/cache/yum";
            break;
        case PackageTool::ZYPPER:
            candidates << "/var/cache/zypp/packages";
            break;
        case PackageTool::APT:
        case PackageTool::APT_RPM:
            candidates << "/var/cache/apt/archives";
            break;
        case PackageTool::PACMAN:
            candidates << "/var/cache/pacman/pkg";
            break;
        default:
            break;
    }
    QStringList existing;
    for (const QString &d : candidates)
        if (QDir(d).exists())
            existing << d;
    return existing;
}

// Recursive on-disk size of a path (file or directory).
quint64 pathSize(const QString &path)
{
    QFileInfo fi(path);
    if (fi.isSymLink())
        return 0;
    if (fi.isFile())
        return fi.size();
    if (fi.isDir()) {
        quint64 total = 0;
        QDirIterator it(path, QDir::Files | QDir::Hidden | QDir::System | QDir::NoSymLinks,
                        QDirIterator::Subdirectories);
        while (it.hasNext()) {
            it.next();
            total += it.fileInfo().size();
        }
        return total;
    }
    return 0;
}

quint64 listSize(const QFileInfoList &list)
{
    quint64 total = 0;
    for (const QFileInfo &fi : list)
        total += pathSize(fi.absoluteFilePath());
    return total;
}

// File set for a category key (re-fetched at scan and clean time).
QFileInfoList filesFor(const QString &key)
{
    SystemInfo info;
    if (key == "cache")
        return info.getAppCaches();
    if (key == "logs")
        return info.getAppLogs();
    if (key == "crash")
        return info.getCrashReports();
    if (key == "package") {
        QFileInfoList list;
        for (const QString &dir : packageCacheDirs())
            list << QDir(dir).entryInfoList(QDir::Files | QDir::Dirs | QDir::NoDotAndDotDot);
        return list;
    }
    return {};
}

} // namespace

CleanerController::CleanerController(QObject *parent) : QAbstractListModel(parent)
{
    mCats = {
        { "cache",   "Application caches", "database-zap", false, true,  0 },
        { "trash",   "Trash",              "trash-2",      false, true,  0 },
        { "package", "Package cache",      "package",      true,  false, 0 },
        { "logs",    "Application logs",   "notebook-pen", true,  false, 0 },
        { "crash",   "Crash reports",      "octagon-x",    true,  false, 0 },
    };
}

int CleanerController::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid())
        return 0;
    return mCats.size();
}

QVariant CleanerController::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= mCats.size())
        return QVariant();

    const Category &c = mCats.at(index.row());
    switch (role) {
        case KeyRole:      return c.key;
        case LabelRole:    return c.label;
        case IconRole:     return c.icon;
        case SizeTextRole: return mScanned ? FormatUtil::formatBytes(c.sizeBytes) : QStringLiteral("—");
        case SelectedRole: return c.selected;
    }
    return QVariant();
}

QHash<int, QByteArray> CleanerController::roleNames() const
{
    return {
        { KeyRole,      "key" },
        { LabelRole,    "label" },
        { IconRole,     "icon" },
        { SizeTextRole, "sizeText" },
        { SelectedRole, "selected" },
    };
}

QString CleanerController::totalSelectedText() const
{
    quint64 total = 0;
    for (const Category &c : mCats)
        if (c.selected)
            total += c.sizeBytes;
    return FormatUtil::formatBytes(total);
}

void CleanerController::setActive(bool active)
{
    if (active && !mScanned && !mBusy)
        scan();
}

void CleanerController::setBusy(bool busy)
{
    if (mBusy == busy)
        return;
    mBusy = busy;
    emit busyChanged();
}

void CleanerController::setSelected(int index, bool selected)
{
    if (index < 0 || index >= mCats.size())
        return;
    mCats[index].selected = selected;
    emit dataChanged(this->index(index), this->index(index), { SelectedRole });
    emit changed();
}

void CleanerController::scan()
{
    if (mBusy)
        return;
    setBusy(true);

    QStringList keys;
    for (const Category &c : mCats)
        keys << c.key;

    (void) QtConcurrent::run([this, keys]() {
        QList<quint64> sizes;
        for (const QString &key : keys) {
            if (key == "trash")
                sizes << pathSize(trashPath() + "/files");
            else
                sizes << listSize(filesFor(key));
        }
        QMetaObject::invokeMethod(
            this, [this, sizes]() { applySizes(sizes); }, Qt::QueuedConnection);
    });
}

void CleanerController::applySizes(const QList<quint64> &sizes)
{
    for (int i = 0; i < mCats.size() && i < sizes.size(); ++i)
        mCats[i].sizeBytes = sizes.at(i);

    mScanned = true;
    emit scannedChanged();
    if (!mCats.isEmpty())
        emit dataChanged(index(0), index(mCats.size() - 1));
    emit changed();
    setBusy(false);
}

void CleanerController::requestDetails(const QString &key)
{
    (void) QtConcurrent::run([this, key]() {
        // Collect (name, size) for each entry this category would remove.
        QList<std::pair<QString, quint64>> entries;

        if (key == "trash") {
            QDir d(trashPath() + "/files");
            const QFileInfoList list =
                d.entryInfoList(QDir::Files | QDir::Dirs | QDir::NoDotAndDotDot | QDir::Hidden);
            for (const QFileInfo &fi : list)
                entries.append({ fi.fileName(), pathSize(fi.absoluteFilePath()) });
        } else {
            const QFileInfoList list = filesFor(key);
            for (const QFileInfo &fi : list)
                entries.append({ fi.fileName(), pathSize(fi.absoluteFilePath()) });
        }

        std::sort(entries.begin(), entries.end(),
                  [](const std::pair<QString, quint64> &a, const std::pair<QString, quint64> &b) {
                      return a.second > b.second;
                  });

        QVariantList items;
        for (const auto &e : entries) {
            QVariantMap m;
            m["name"] = e.first;
            m["sizeText"] = FormatUtil::formatBytes(e.second);
            items.append(m);
        }

        QMetaObject::invokeMethod(
            this, [this, key, items]() { emit detailsReady(key, items); },
            Qt::QueuedConnection);
    });
}

void CleanerController::clean()
{
    if (mBusy)
        return;

    // Snapshot the selection for the worker.
    QStringList userKeys, rootKeys;
    bool cleanTrash = false;
    for (const Category &c : mCats) {
        if (!c.selected)
            continue;
        if (c.key == "trash")
            cleanTrash = true;
        else if (c.needsSudo)
            rootKeys << c.key;
        else
            userKeys << c.key;
    }

    if (userKeys.isEmpty() && rootKeys.isEmpty() && !cleanTrash)
        return;

    setBusy(true);

    (void) QtConcurrent::run([this, userKeys, rootKeys, cleanTrash]() {
        // User-owned junk — remove directly.
        for (const QString &key : userKeys) {
            const QFileInfoList files = filesFor(key);
            for (const QFileInfo &fi : files) {
                if (fi.isDir())
                    QDir(fi.absoluteFilePath()).removeRecursively();
                else
                    QFile::remove(fi.absoluteFilePath());
            }
        }

        if (cleanTrash) {
            QDir(trashPath() + "/files").removeRecursively();
            QDir(trashPath() + "/info").removeRecursively();
        }

        // Root-owned junk — one elevated rm.
        QStringList rootPaths;
        for (const QString &key : rootKeys)
            for (const QFileInfo &fi : filesFor(key))
                rootPaths << fi.absoluteFilePath();

        if (!rootPaths.isEmpty()) {
            try {
                CommandUtil::sudoExec("rm", QStringList() << "-rf" << rootPaths);
            } catch (const QString &ex) {
                qCritical() << ex;
            }
        }

        QMetaObject::invokeMethod(
            this,
            [this]() {
                setBusy(false);
                scan();
            },
            Qt::QueuedConnection);
    });
}

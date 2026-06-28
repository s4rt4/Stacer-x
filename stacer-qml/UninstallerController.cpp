#include "UninstallerController.h"

#include <algorithm>

#include <QDir>
#include <QDirIterator>
#include <QFile>
#include <QFileInfo>
#include <QStandardPaths>
#include <QVariantMap>
#include <QtConcurrent>

#include "Tools/package_tool.h"
#include "Utils/command_util.h"
#include "Utils/format_util.h"

namespace {

// User dirs where apps leave config/cache/state behind (not tracked by rpm).
QStringList leftoverRoots()
{
    const QString home = QDir::homePath();
    return { home + "/.config", home + "/.cache", home + "/.local/share", home + "/.local/state" };
}

quint64 dirSize(const QString &path)
{
    quint64 total = 0;
    QDirIterator it(path, QDir::Files | QDir::Hidden | QDir::System | QDir::NoSymLinks,
                    QDirIterator::Subdirectories);
    while (it.hasNext()) {
        it.next();
        total += it.fileInfo().size();
    }
    return total;
}

// Folders under the leftover roots whose name matches a package (case-insensitive).
QStringList matchedLeftovers(const QSet<QString> &packages)
{
    QStringList result;
    for (const QString &root : leftoverRoots()) {
        QDir dir(root);
        if (!dir.exists())
            continue;
        const QFileInfoList entries =
            dir.entryInfoList(QDir::Dirs | QDir::Files | QDir::NoDotAndDotDot | QDir::Hidden);
        for (const QFileInfo &fi : entries) {
            const QString name = fi.fileName();
            for (const QString &pkg : packages) {
                if (name.compare(pkg, Qt::CaseInsensitive) == 0) {
                    result << fi.absoluteFilePath();
                    break;
                }
            }
        }
    }
    return result;
}

bool autoremoveDeps()
{
    try {
        switch (PackageTool::currentPackageTool) {
            case PackageTool::DNF:
            case PackageTool::ZYPPER:
                CommandUtil::sudoExec("dnf", { "autoremove", "-y" });
                return true;
            case PackageTool::YUM:
                CommandUtil::sudoExec("yum", { "autoremove", "-y" });
                return true;
            case PackageTool::APT:
            case PackageTool::APT_RPM:
                CommandUtil::sudoExec("apt-get", { "autoremove", "-y" });
                return true;
            case PackageTool::PACMAN:
                CommandUtil::sudoExec(
                    "bash", { "-c", "pacman -Qtdq | pacman -Rns --noconfirm - || true" });
                return true;
            default:
                return false;
        }
    } catch (const QString &ex) {
        qCritical() << ex;
        return false;
    }
}


// rpm package names WITHOUT the version/arch suffix. PackageTool::getRpmPackages()
// returns full NEVRA (e.g. "chromium-128.0-1.fc43.x86_64"), which makes for an
// unreadable list AND breaks leftover matching (folder "chromium" never equals
// the NEVRA string). Querying %{NAME} gives clean names that both read well and
// match user config/cache folders. dnf/yum/zypper all remove by bare name fine.
QStringList rpmPackageNames()
{
    QStringList list;
    try {
        list = CommandUtil::exec("bash", { "-c", "rpm -qa --qf '%{NAME}\\n' 2> /dev/null" })
                   .split('\n');
    } catch (const QString &ex) {
        qCritical() << ex;
    }
    return list;
}

QStringList listPackages()
{
    switch (PackageTool::currentPackageTool) {
        case PackageTool::APT:
        case PackageTool::APT_RPM:
            return PackageTool::getDpkgPackages();
        case PackageTool::DNF:
        case PackageTool::YUM:
        case PackageTool::ZYPPER:
            return rpmPackageNames();
        case PackageTool::PACMAN:
            return PackageTool::getPacmanPackages();
        default:
            return {};
    }
}

bool removePackages(const QStringList &packages)
{
    switch (PackageTool::currentPackageTool) {
        case PackageTool::APT:
        case PackageTool::APT_RPM:
            return PackageTool::dpkgRemovePackages(packages);
        case PackageTool::DNF:
        case PackageTool::ZYPPER:
            return PackageTool::dnfRemovePackages(packages);
        case PackageTool::YUM:
            return PackageTool::yumRemovePackages(packages);
        case PackageTool::PACMAN:
            return PackageTool::pacmanRemovePackages(packages);
        default:
            return false;
    }
}

QString managerName()
{
    switch (PackageTool::currentPackageTool) {
        case PackageTool::APT:     return "apt";
        case PackageTool::APT_RPM: return "apt-rpm";
        case PackageTool::DNF:     return "dnf";
        case PackageTool::YUM:     return "yum";
        case PackageTool::ZYPPER:  return "zypper";
        case PackageTool::PACMAN:  return "pacman";
        default:                   return "unknown";
    }
}

} // namespace

UninstallerController::UninstallerController(QObject *parent) : QAbstractListModel(parent)
{
    mManager = managerName();
}

int UninstallerController::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid())
        return 0;
    return mRows.size();
}

QVariant UninstallerController::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= mRows.size())
        return QVariant();

    const QString &name = mRows.at(index.row());
    switch (role) {
        case NameRole:     return name;
        case SelectedRole: return mSelected.contains(name);
    }
    return QVariant();
}

QHash<int, QByteArray> UninstallerController::roleNames() const
{
    return {
        { NameRole,     "name" },
        { SelectedRole, "selected" },
    };
}

void UninstallerController::setActive(bool active)
{
    if (active && !mLoaded && !mBusy)
        reload();
}

void UninstallerController::setBusy(bool busy)
{
    if (mBusy == busy)
        return;
    mBusy = busy;
    emit busyChanged();
}

void UninstallerController::reload()
{
    if (mBusy)
        return;
    setBusy(true);

    (void) QtConcurrent::run([this]() {
        QStringList pkgs = listPackages();
        pkgs.removeAll(QString());
        std::sort(pkgs.begin(), pkgs.end(), [](const QString &a, const QString &b) {
            return a.compare(b, Qt::CaseInsensitive) < 0;
        });
        // %{NAME} repeats multi-arch packages (e.g. glibc.i686 + glibc.x86_64);
        // identical names are now adjacent, so collapse them.
        pkgs.erase(std::unique(pkgs.begin(), pkgs.end()), pkgs.end());
        QMetaObject::invokeMethod(
            this, [this, pkgs]() { setPackages(pkgs); }, Qt::QueuedConnection);
    });
}

void UninstallerController::setPackages(const QStringList &packages)
{
    mAll = packages;
    mLoaded = true;
    setBusy(false);
    applyFilter();
}

void UninstallerController::setFilter(const QString &filter)
{
    const QString f = filter.trimmed();
    if (f == mFilter)
        return;
    mFilter = f;
    emit filterChanged();
    applyFilter();
}

void UninstallerController::applyFilter()
{
    QStringList filtered;
    if (mFilter.isEmpty()) {
        filtered = mAll;
    } else {
        for (const QString &p : mAll)
            if (p.contains(mFilter, Qt::CaseInsensitive))
                filtered.append(p);
    }

    beginResetModel();
    mRows = filtered;
    endResetModel();
    emit countChanged();
}

void UninstallerController::toggle(const QString &name)
{
    if (mSelected.contains(name))
        mSelected.remove(name);
    else
        mSelected.insert(name);

    const int row = mRows.indexOf(name);
    if (row >= 0)
        emit dataChanged(index(row), index(row), { SelectedRole });
    emit selectionChanged();
}

void UninstallerController::clearSelection()
{
    if (mSelected.isEmpty())
        return;
    mSelected.clear();
    if (!mRows.isEmpty())
        emit dataChanged(index(0), index(mRows.size() - 1), { SelectedRole });
    emit selectionChanged();
}

void UninstallerController::removeSelected()
{
    if (mBusy || mSelected.isEmpty())
        return;

    const QStringList packages = mSelected.values();
    const QSet<QString> selected = mSelected;
    const bool alsoConfig = mRemoveConfig;
    setBusy(true);

    (void) QtConcurrent::run([this, packages, selected, alsoConfig]() {
        removePackages(packages);

        // Remove matching user config/cache leftovers (user-owned, no elevation).
        if (alsoConfig) {
            for (const QString &path : matchedLeftovers(selected)) {
                if (QFileInfo(path).isDir())
                    QDir(path).removeRecursively();
                else
                    QFile::remove(path);
            }
        }

        QMetaObject::invokeMethod(
            this,
            [this]() {
                mSelected.clear();
                emit selectionChanged();
                mLoaded = false;
                setBusy(false);
                reload();
            },
            Qt::QueuedConnection);
    });
}

void UninstallerController::setRemoveConfig(bool on)
{
    if (mRemoveConfig == on)
        return;
    mRemoveConfig = on;
    emit removeConfigChanged();
}

void UninstallerController::requestLeftovers()
{
    const QSet<QString> selected = mSelected;
    (void) QtConcurrent::run([this, selected]() {
        QVariantList items;
        for (const QString &path : matchedLeftovers(selected)) {
            QVariantMap m;
            m["path"] = path;
            m["sizeText"] = FormatUtil::formatBytes(dirSize(path));
            items.append(m);
        }
        QMetaObject::invokeMethod(
            this, [this, items]() { emit leftoversReady(items); }, Qt::QueuedConnection);
    });
}

void UninstallerController::autoremove()
{
    if (mBusy)
        return;
    setBusy(true);

    (void) QtConcurrent::run([this]() {
        autoremoveDeps();
        QMetaObject::invokeMethod(
            this,
            [this]() {
                mLoaded = false;
                setBusy(false);
                reload();
            },
            Qt::QueuedConnection);
    });
}

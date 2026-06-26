#include "ProcessesController.h"

#include <algorithm>

#include "Info/system_info.h"
#include "Utils/command_util.h"
#include "Utils/format_util.h"

ProcessesController::ProcessesController(QObject *parent) : QAbstractListModel(parent)
{
    SystemInfo info;
    mCurrentUser = info.getUsername();

    mTimer.setInterval(2000);
    connect(&mTimer, &QTimer::timeout, this, &ProcessesController::refresh);
}

int ProcessesController::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid())
        return 0;
    return mRows.size();
}

QVariant ProcessesController::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= mRows.size())
        return QVariant();

    const Process &p = mRows.at(index.row());
    switch (role) {
        case PidRole:   return static_cast<int>(p.getPid());
        case CmdRole:   return p.getCmd();
        case UserRole:  return p.getUname();
        case CpuRole:   return p.getPcpu();
        case MemRole:   return FormatUtil::formatBytes(p.getRss());
        case NiceRole:  return p.getNice();
        case StateRole: return p.getState();
    }
    return QVariant();
}

QHash<int, QByteArray> ProcessesController::roleNames() const
{
    return {
        { PidRole,   "pid" },
        { CmdRole,   "cmd" },
        { UserRole,  "uname" },
        { CpuRole,   "pcpu" },
        { MemRole,   "mem" },
        { NiceRole,  "nice" },
        { StateRole, "state" },
    };
}

void ProcessesController::setActive(bool active)
{
    if (active) {
        refresh();
        mTimer.start();
    } else {
        mTimer.stop();
    }
}

void ProcessesController::refresh()
{
    mProcessInfo.updateProcesses();

    // Drop the `ps` enumeration command we spawn ourselves — it appears in its
    // own output, and being a sub-second process its %cpu is a meaningless
    // spike (cputime / tiny lifetime) that lands it at the top of the list.
    // The column spec "uname:50" is unique to our invocation, so it's a safe
    // marker that won't match any unrelated process.
    mAll.clear();
    for (const Process &p : mProcessInfo.getProcessList()) {
        const QString cmd = p.getCmd();
        if (cmd.contains(QStringLiteral("-weo")) && cmd.contains(QStringLiteral("uname:50")))
            continue;
        mAll.append(p);
    }
    std::sort(mAll.begin(), mAll.end(),
              [](const Process &a, const Process &b) { return a.getPcpu() > b.getPcpu(); });

    applyFilter();
}

void ProcessesController::setFilter(const QString &filter)
{
    const QString f = filter.trimmed();
    if (f == mFilter)
        return;
    mFilter = f;
    emit filterChanged();
    applyFilter();
}

void ProcessesController::applyFilter()
{
    QList<Process> filtered;
    if (mFilter.isEmpty()) {
        filtered = mAll;
    } else {
        for (const Process &p : mAll) {
            if (p.getCmd().contains(mFilter, Qt::CaseInsensitive)
                || p.getUname().contains(mFilter, Qt::CaseInsensitive))
                filtered.append(p);
        }
    }

    if (filtered.size() == mRows.size() && !mRows.isEmpty()) {
        // Same row count — update in place so the view keeps its scroll position.
        mRows = filtered;
        emit dataChanged(index(0), index(mRows.size() - 1));
    } else {
        beginResetModel();
        mRows = filtered;
        endResetModel();
        emit countChanged();
    }
}

void ProcessesController::killProcess(int pid)
{
    if (pid <= 0)
        return;

    // Find the owner to decide whether elevation is needed.
    QString uname;
    for (const Process &p : mRows) {
        if (static_cast<int>(p.getPid()) == pid) {
            uname = p.getUname();
            break;
        }
    }

    try {
        if (uname == mCurrentUser)
            CommandUtil::exec("kill", { QString::number(pid) });
        else
            CommandUtil::sudoExec("kill", { QString::number(pid) });
    } catch (const QString &ex) {
        qCritical() << ex;
    }

    refresh();
}

void ProcessesController::setPriority(int pid, int nice)
{
    if (pid <= 0)
        return;

    QString uname;
    for (const Process &p : mAll) {
        if (static_cast<int>(p.getPid()) == pid) {
            uname = p.getUname();
            break;
        }
    }

    const QStringList args = { "-n", QString::number(nice), "-p", QString::number(pid) };
    try {
        // Raising priority (negative nice) or touching another user's process
        // requires elevation; otherwise the user can renice their own down.
        if (uname == mCurrentUser && nice >= 0)
            CommandUtil::exec("renice", args);
        else
            CommandUtil::sudoExec("renice", args);
    } catch (const QString &ex) {
        qCritical() << ex;
    }

    refresh();
}

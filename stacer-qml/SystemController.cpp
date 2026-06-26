#include "SystemController.h"

#include <QFile>
#include <QProcess>
#include <QSettings>
#include <QStorageInfo>
#include <QtConcurrent>

#include "Utils/command_util.h"
#include "Utils/format_util.h"

SystemController::SystemController(QObject *parent) : QObject(parent)
{
    QSettings s;
    mAlertsEnabled = s.value("alerts/enabled", false).toBool();
    mCpuAlert = s.value("alerts/cpu", 90).toInt();
    mMemAlert = s.value("alerts/mem", 90).toInt();
    mDiskAlert = s.value("alerts/disk", 90).toInt();

    for (int i = 0; i < kCpuHistory; ++i)
        mCpuHist << 0;

    connect(&mTimer, &QTimer::timeout, this, &SystemController::refresh);
    mTimer.setInterval(1000);
    mTimer.start();
    refresh();
}

void SystemController::setAlertsEnabled(bool on)
{
    if (mAlertsEnabled == on)
        return;
    mAlertsEnabled = on;
    QSettings().setValue("alerts/enabled", on);
    emit alertsChanged();
}

static int clampPct(int v) { return v < 0 ? 0 : (v > 100 ? 100 : v); }

void SystemController::setCpuAlert(int v)
{
    v = clampPct(v);
    if (mCpuAlert == v) return;
    mCpuAlert = v;
    QSettings().setValue("alerts/cpu", v);
    emit alertsChanged();
}

void SystemController::setMemAlert(int v)
{
    v = clampPct(v);
    if (mMemAlert == v) return;
    mMemAlert = v;
    QSettings().setValue("alerts/mem", v);
    emit alertsChanged();
}

void SystemController::setDiskAlert(int v)
{
    v = clampPct(v);
    if (mDiskAlert == v) return;
    mDiskAlert = v;
    QSettings().setValue("alerts/disk", v);
    emit alertsChanged();
}

void SystemController::notify(const QString &title, const QString &body)
{
    QProcess::startDetached(
        "notify-send", { "-i", "stacer-x", "-a", "Stacer-X", "-u", "normal", title, body });
}

void SystemController::checkAlerts()
{
    if (!mAlertsEnabled)
        return;

    const int cpu = mCpuPercent;
    const int mem = memPercent();
    const int disk = rootPercent();

    // Fire once on crossing above the threshold; rearm when it drops back below.
    if (mCpuAlert > 0) {
        if (cpu >= mCpuAlert && !mCpuAlerting) {
            mCpuAlerting = true;
            notify("High CPU usage", QString("CPU usage is at %1% (limit %2%).").arg(cpu).arg(mCpuAlert));
        } else if (cpu < mCpuAlert) {
            mCpuAlerting = false;
        }
    }
    if (mMemAlert > 0) {
        if (mem >= mMemAlert && !mMemAlerting) {
            mMemAlerting = true;
            notify("High memory usage", QString("Memory usage is at %1% (limit %2%).").arg(mem).arg(mMemAlert));
        } else if (mem < mMemAlert) {
            mMemAlerting = false;
        }
    }
    if (mDiskAlert > 0) {
        if (disk >= mDiskAlert && !mDiskAlerting) {
            mDiskAlerting = true;
            notify("Low disk space", QString("Root disk usage is at %1% (limit %2%).").arg(disk).arg(mDiskAlert));
        } else if (disk < mDiskAlert) {
            mDiskAlerting = false;
        }
    }
}

void SystemController::refresh()
{
    // Single source of CPU usage in the app — getCpuPercent() keeps per-CPU
    // delta state in process-global statics, so only one poller may call it.
    const QList<int> percents = mCpuInfo.getCpuPercents();
    if (!percents.isEmpty())
        mCpuPercent = percents.first();
    mCores.clear();
    for (int i = 1; i < percents.size(); ++i)
        mCores.append(percents.at(i));
    mCpuHist.append(mCpuPercent);
    while (mCpuHist.size() > kCpuHistory)
        mCpuHist.removeFirst();

    const QList<double> loads = mCpuInfo.getLoadAvgs();
    if (loads.size() >= 3)
        mLoadText = QString("%1  ·  %2  ·  %3")
                        .arg(loads.at(0), 0, 'f', 2)
                        .arg(loads.at(1), 0, 'f', 2)
                        .arg(loads.at(2), 0, 'f', 2);

    mMemoryInfo.updateMemoryInfo();

    const QStorageInfo root = QStorageInfo::root();
    mRootSize = root.bytesTotal();
    mRootUsed = root.bytesTotal() - root.bytesFree();

    // CPU clock — average of live per-core MHz from /proc/cpuinfo (cheap).
    // Avoids spawning `lscpu` every tick (the old getAvgClock path).
    const QList<double> clocks = mCpuInfo.getClocks();
    if (!clocks.isEmpty()) {
        double sum = 0;
        for (double c : clocks)
            sum += c;
        mCpuClockText = QString("%1 GHz").arg(sum / clocks.size() / 1000.0, 0, 'f', 2);
    }

    // Uptime from /proc/uptime
    QFile up("/proc/uptime");
    if (up.open(QIODevice::ReadOnly | QIODevice::Text)) {
        const double secs = QString::fromUtf8(up.readAll()).section(' ', 0, 0).toDouble();
        const qint64 s = static_cast<qint64>(secs);
        const qint64 d = s / 86400, h = (s % 86400) / 3600, m = (s % 3600) / 60;
        if (d > 0)
            mUptimeText = QString("%1d %2h %3m").arg(d).arg(h).arg(m);
        else if (h > 0)
            mUptimeText = QString("%1h %2m").arg(h).arg(m);
        else
            mUptimeText = QString("%1m").arg(m);
    }

    emit metricsChanged();
    checkAlerts();
}

int SystemController::memPercent() const
{
    const quint64 total = mMemoryInfo.getMemTotal();
    if (total == 0)
        return 0;
    return static_cast<int>(mMemoryInfo.getMemUsed() * 100 / total);
}

QString SystemController::memUsedText() const
{
    return FormatUtil::formatBytes(mMemoryInfo.getMemUsed());
}

QString SystemController::memTotalText() const
{
    return FormatUtil::formatBytes(mMemoryInfo.getMemTotal());
}

QString SystemController::rootUsedText() const
{
    return FormatUtil::formatBytes(mRootUsed);
}

QString SystemController::rootTotalText() const
{
    return FormatUtil::formatBytes(mRootSize);
}

int SystemController::rootPercent() const
{
    if (mRootSize == 0)
        return 0;
    return static_cast<int>(mRootUsed * 100 / mRootSize);
}

QString SystemController::lastBoostFreedText() const
{
    return FormatUtil::formatBytes(mLastFreed);
}

void SystemController::boost()
{
    if (mBoosting)
        return;

    // Baseline memory before freeing caches.
    mMemoryInfo.updateMemoryInfo();
    mMemBefore = mMemoryInfo.getMemUsed();

    mBoosting = true;
    emit boostingChanged();

    (void) QtConcurrent::run([this]() {
        try {
            // Flush dirty pages, then drop reclaimable caches.
            CommandUtil::sudoExec(
                "sh", { "-c", "sync; echo 3 > /proc/sys/vm/drop_caches" });
        } catch (const QString &ex) {
            qCritical() << ex;
        }

        QMetaObject::invokeMethod(
            this,
            [this]() {
                mBoosting = false;
                emit boostingChanged();

                mMemoryInfo.updateMemoryInfo();
                const quint64 after = mMemoryInfo.getMemUsed();
                mLastFreed = (mMemBefore > after) ? (mMemBefore - after) : 0;

                refresh();
                emit boostFinished();
            },
            Qt::QueuedConnection);
    });
}

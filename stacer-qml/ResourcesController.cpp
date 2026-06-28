#include "ResourcesController.h"

#include <QDir>
#include <QFile>
#include <QStandardPaths>
#include <QVariantMap>
#include <QtConcurrent>

#include "Utils/command_util.h"
#include "Utils/format_util.h"

namespace {

int readIntFile(const QString &path)
{
    QFile f(path);
    if (!f.open(QIODevice::ReadOnly | QIODevice::Text))
        return 0;
    return QString::fromUtf8(f.readAll()).trimmed().toInt();
}

// First /sys/class/drm/card*/device/gpu_busy_percent (AMD/Intel), if any.
QString findSysfsGpu()
{
    QDir drm("/sys/class/drm");
    const QStringList cards = drm.entryList({ "card[0-9]*" }, QDir::Dirs);
    for (const QString &card : cards) {
        const QString p = "/sys/class/drm/" + card + "/device/gpu_busy_percent";
        if (QFile::exists(p))
            return p;
    }
    return QString();
}

void pushSample(QVariantList &list, double value, int cap)
{
    list.append(value);
    while (list.size() > cap)
        list.removeFirst();
}

} // namespace

ResourcesController::ResourcesController(QObject *parent) : QObject(parent)
{
    mTimer.setInterval(1000);
    connect(&mTimer, &QTimer::timeout, this, &ResourcesController::refresh);

    mGpuPath = findSysfsGpu();
    mNvProg = QStandardPaths::findExecutable("nvidia-smi");
    mHasNvidia = !mNvProg.isEmpty();

    for (int i = 0; i < kHistory; ++i) {
        mMemHist << 0;
        mGpuHist << 0;
        mNvHist << 0;
        mDownHist << 0;
        mUpHist << 0;
        mDiskHist << 0;
    }
}

void ResourcesController::setActive(bool active)
{
    if (active) {
        refresh();
        mTimer.start();
    } else {
        mTimer.stop();
    }
}

void ResourcesController::refresh()
{
    // NOTE: CPU usage is intentionally NOT polled here. getCpuPercent() keeps
    // process-global delta statics, so two pollers corrupt each other. The
    // single CPU poller is SystemController; the CPU chart reads its history.

    // Memory
    mMemoryInfo.updateMemoryInfo();
    const quint64 memTotal = mMemoryInfo.getMemTotal();
    mMem = memTotal ? static_cast<int>(mMemoryInfo.getMemUsed() * 100 / memTotal) : 0;
    mMemText = FormatUtil::formatBytes(mMemoryInfo.getMemUsed()) + " / "
               + FormatUtil::formatBytes(memTotal);

    // GPU (integrated, sysfs)
    if (!mGpuPath.isEmpty())
        mGpu = readIntFile(mGpuPath);

    // Network — bytes since last tick (interval is 1s).
    const quint64 rx = mNetworkInfo.getRXbytes();
    const quint64 tx = mNetworkInfo.getTXbytes();

    // Disk I/O — cumulative read/write bytes across block devices.
    const QList<quint64> io = mDiskInfo.getDiskIO();
    const quint64 rd = io.size() > 0 ? io.at(0) : 0;
    const quint64 wr = io.size() > 1 ? io.at(1) : 0;

    double down = 0, up = 0, diskRead = 0, diskWrite = 0;
    if (mHasLast) {
        down = (rx >= mLastRx) ? (rx - mLastRx) : 0;
        up = (tx >= mLastTx) ? (tx - mLastTx) : 0;
        diskRead = (rd >= mLastRead) ? (rd - mLastRead) : 0;
        diskWrite = (wr >= mLastWrite) ? (wr - mLastWrite) : 0;
    }
    mLastRx = rx;
    mLastTx = tx;
    mLastRead = rd;
    mLastWrite = wr;
    mHasLast = true;

    mDownText = FormatUtil::formatBytes(static_cast<quint64>(down)) + "/s";
    mUpText = FormatUtil::formatBytes(static_cast<quint64>(up)) + "/s";
    mDiskText = "R " + FormatUtil::formatBytes(static_cast<quint64>(diskRead)) + "/s   W "
                + FormatUtil::formatBytes(static_cast<quint64>(diskWrite)) + "/s";

    // Per-partition disk usage — changes slowly and enumerating mounted
    // volumes is comparatively costly, so refresh it only every few ticks.
    if (mDiskTick % 5 == 0) {
        mDiskInfo.updateDiskInfo();
        mDisks.clear();
        QSet<QString> seenDevices;
        for (const Disk *d : mDiskInfo.getDisks()) {
            if (d->size == 0)
                continue;
            // Real block devices only — drop tmpfs, /run/credentials, overlay…
            if (!d->device.startsWith("/dev/"))
                continue;
            // …and snap/squashfs loop mounts, which aren't user storage.
            if (d->fileSystemType == "squashfs" || d->device.startsWith("/dev/loop"))
                continue;
            // btrfs subvolumes (Fedora mounts / and /home from the same
            // /dev/sdaN, each reporting the whole-fs size) would list and
            // double-count the device — show each physical device once.
            if (seenDevices.contains(d->device))
                continue;
            seenDevices.insert(d->device);

            QVariantMap m;
            m["name"] = d->name;
            m["device"] = d->device;
            m["usedText"] = FormatUtil::formatBytes(d->used);
            m["totalText"] = FormatUtil::formatBytes(d->size);
            m["freeText"] = FormatUtil::formatBytes(d->free);
            m["percent"] = static_cast<int>(d->used * 100 / d->size);
            m["usedBytes"] = static_cast<double>(d->used);
            m["sizeBytes"] = static_cast<double>(d->size);
            mDisks.append(m);
        }
    }
    ++mDiskTick;

    pushSample(mMemHist, mMem, kHistory);
    pushSample(mGpuHist, mGpu, kHistory);
    pushSample(mNvHist, mNv, kHistory);
    pushSample(mDownHist, down, kHistory);
    pushSample(mUpHist, up, kHistory);
    pushSample(mDiskHist, diskRead + diskWrite, kHistory);

    // NVIDIA — query off-thread so the per-second tick never blocks on the
    // nvidia-smi subprocess. At most one query in flight at a time.
    if (mHasNvidia && !mNvBusy) {
        mNvBusy = true;
        const QString prog = mNvProg;
        (void) QtConcurrent::run([this, prog]() {
            int util = 0;
            QString text;
            try {
                const QString out = CommandUtil::exec(
                    prog,
                    { "--query-gpu=utilization.gpu,memory.used,memory.total",
                      "--format=csv,noheader,nounits" });
                const QStringList parts = out.section('\n', 0, 0).split(',');
                if (parts.size() >= 3) {
                    util = parts.at(0).trimmed().toInt();
                    text = parts.at(1).trimmed() + " / " + parts.at(2).trimmed() + " MiB";
                }
            } catch (const QString &ex) {
                qCritical() << ex;
            }
            QMetaObject::invokeMethod(
                this,
                [this, util, text]() {
                    mNv = util;
                    mNvText = text;
                    mNvBusy = false;
                },
                Qt::QueuedConnection);
        });
    }

    emit updated();
}

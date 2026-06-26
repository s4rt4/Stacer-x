#ifndef RESOURCESCONTROLLER_H
#define RESOURCESCONTROLLER_H

#include <QObject>
#include <QTimer>
#include <QVariantList>

#include "Info/cpu_info.h"
#include "Info/memory_info.h"
#include "Info/network_info.h"
#include "Info/disk_info.h"

// Rolling history of CPU / RAM / network for the Resources charts (`resources`).
// Polls once per second while the page is visible.
class ResourcesController : public QObject
{
    Q_OBJECT
    Q_PROPERTY(int cpuPercent READ cpuPercent NOTIFY updated)
    Q_PROPERTY(int memPercent READ memPercent NOTIFY updated)
    Q_PROPERTY(int gpuPercent READ gpuPercent NOTIFY updated)
    Q_PROPERTY(bool gpuAvailable READ gpuAvailable CONSTANT)
    Q_PROPERTY(int nvPercent READ nvPercent NOTIFY updated)
    Q_PROPERTY(bool nvAvailable READ nvAvailable CONSTANT)
    Q_PROPERTY(QString nvText READ nvText NOTIFY updated)
    Q_PROPERTY(QVariantList nvHistory READ nvHistory NOTIFY updated)
    Q_PROPERTY(QString memText READ memText NOTIFY updated)
    Q_PROPERTY(QString downText READ downText NOTIFY updated)
    Q_PROPERTY(QString upText READ upText NOTIFY updated)
    Q_PROPERTY(QString diskText READ diskText NOTIFY updated)
    Q_PROPERTY(QVariantList cpuHistory READ cpuHistory NOTIFY updated)
    Q_PROPERTY(QVariantList memHistory READ memHistory NOTIFY updated)
    Q_PROPERTY(QVariantList gpuHistory READ gpuHistory NOTIFY updated)
    Q_PROPERTY(QVariantList downHistory READ downHistory NOTIFY updated)
    Q_PROPERTY(QVariantList upHistory READ upHistory NOTIFY updated)
    Q_PROPERTY(QVariantList diskHistory READ diskHistory NOTIFY updated)
    Q_PROPERTY(QVariantList cores READ cores NOTIFY updated)
    Q_PROPERTY(QString loadText READ loadText NOTIFY updated)
    Q_PROPERTY(QVariantList disks READ disks NOTIFY updated)

  public:
    explicit ResourcesController(QObject *parent = nullptr);

    int cpuPercent() const { return mCpu; }
    int memPercent() const { return mMem; }
    int gpuPercent() const { return mGpu; }
    bool gpuAvailable() const { return !mGpuPath.isEmpty(); }
    int nvPercent() const { return mNv; }
    bool nvAvailable() const { return mHasNvidia; }
    QString nvText() const { return mNvText; }
    QVariantList nvHistory() const { return mNvHist; }
    QString memText() const { return mMemText; }
    QString downText() const { return mDownText; }
    QString upText() const { return mUpText; }
    QString diskText() const { return mDiskText; }
    QVariantList cpuHistory() const { return mCpuHist; }
    QVariantList memHistory() const { return mMemHist; }
    QVariantList gpuHistory() const { return mGpuHist; }
    QVariantList downHistory() const { return mDownHist; }
    QVariantList upHistory() const { return mUpHist; }
    QVariantList diskHistory() const { return mDiskHist; }
    QVariantList cores() const { return mCores; }
    QString loadText() const { return mLoadText; }
    QVariantList disks() const { return mDisks; }

    Q_INVOKABLE void setActive(bool active);

  signals:
    void updated();

  private slots:
    void refresh();

  private:
    static const int kHistory = 60;

    CpuInfo mCpuInfo;
    MemoryInfo mMemoryInfo;
    NetworkInfo mNetworkInfo;
    DiskInfo mDiskInfo;
    QTimer mTimer;

    int mCpu = 0;
    int mMem = 0;
    int mGpu = 0;
    int mNv = 0;
    QString mMemText;
    QString mDownText;
    QString mUpText;
    QString mDiskText;
    QString mNvText;
    QString mLoadText;
    QVariantList mCores;
    QVariantList mDisks;
    QString mGpuPath;
    QString mNvProg;
    bool mHasNvidia = false;
    bool mNvBusy = false;

    QVariantList mCpuHist;
    QVariantList mMemHist;
    QVariantList mGpuHist;
    QVariantList mNvHist;
    QVariantList mDownHist;
    QVariantList mUpHist;
    QVariantList mDiskHist;

    quint64 mLastRx = 0;
    quint64 mLastTx = 0;
    quint64 mLastRead = 0;
    quint64 mLastWrite = 0;
    bool mHasLast = false;
    int mDiskTick = 0;
};

#endif // RESOURCESCONTROLLER_H

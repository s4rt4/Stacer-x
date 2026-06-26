#ifndef SYSTEMCONTROLLER_H
#define SYSTEMCONTROLLER_H

#include <QObject>
#include <QTimer>
#include <QString>

#include "Info/cpu_info.h"
#include "Info/memory_info.h"
#include "Info/system_info.h"

// Thin bridge over stacer-core, exposed to QML. View-only: no system logic
// lives in QML, all numbers come from stacer-core here.
class SystemController : public QObject
{
    Q_OBJECT

    Q_PROPERTY(int cpuPercent READ cpuPercent NOTIFY metricsChanged)
    Q_PROPERTY(int memPercent READ memPercent NOTIFY metricsChanged)
    Q_PROPERTY(QString memUsedText READ memUsedText NOTIFY metricsChanged)
    Q_PROPERTY(QString memTotalText READ memTotalText NOTIFY metricsChanged)

    Q_PROPERTY(QString rootUsedText READ rootUsedText NOTIFY metricsChanged)
    Q_PROPERTY(QString rootTotalText READ rootTotalText NOTIFY metricsChanged)
    Q_PROPERTY(int rootPercent READ rootPercent NOTIFY metricsChanged)

    Q_PROPERTY(QString hostname READ hostname CONSTANT)
    Q_PROPERTY(QString distribution READ distribution CONSTANT)
    Q_PROPERTY(QString kernel READ kernel CONSTANT)
    Q_PROPERTY(QString cpuModel READ cpuModel CONSTANT)
    Q_PROPERTY(QString cpuCore READ cpuCore CONSTANT)
    Q_PROPERTY(QString platform READ platform CONSTANT)
    Q_PROPERTY(QString cpuClockText READ cpuClockText NOTIFY metricsChanged)
    Q_PROPERTY(QString uptimeText READ uptimeText NOTIFY metricsChanged)
    Q_PROPERTY(QVariantList cores READ cores NOTIFY metricsChanged)
    Q_PROPERTY(QString loadText READ loadText NOTIFY metricsChanged)
    Q_PROPERTY(QVariantList cpuHistory READ cpuHistory NOTIFY metricsChanged)

    Q_PROPERTY(bool boosting READ boosting NOTIFY boostingChanged)
    Q_PROPERTY(QString lastBoostFreedText READ lastBoostFreedText NOTIFY boostFinished)
    Q_PROPERTY(double lastBoostFreedBytes READ lastBoostFreedBytes NOTIFY boostFinished)

    // Resource alert thresholds (percent; 0 = disabled). Persisted.
    Q_PROPERTY(bool alertsEnabled READ alertsEnabled WRITE setAlertsEnabled NOTIFY alertsChanged)
    Q_PROPERTY(int cpuAlert READ cpuAlert WRITE setCpuAlert NOTIFY alertsChanged)
    Q_PROPERTY(int memAlert READ memAlert WRITE setMemAlert NOTIFY alertsChanged)
    Q_PROPERTY(int diskAlert READ diskAlert WRITE setDiskAlert NOTIFY alertsChanged)

  public:
    explicit SystemController(QObject *parent = nullptr);

    int cpuPercent() const { return mCpuPercent; }
    int memPercent() const;
    QString memUsedText() const;
    QString memTotalText() const;

    QString rootUsedText() const;
    QString rootTotalText() const;
    int rootPercent() const;

    QString hostname() const { return mSystemInfo.getHostname(); }
    QString distribution() const { return mSystemInfo.getDistribution(); }
    QString kernel() const { return mSystemInfo.getKernel(); }
    QString cpuModel() const { return mSystemInfo.getCpuModel(); }
    QString cpuCore() const { return mSystemInfo.getCpuCore(); }
    QString platform() const { return mSystemInfo.getPlatform(); }
    QString cpuClockText() const { return mCpuClockText; }
    QString uptimeText() const { return mUptimeText; }
    QVariantList cores() const { return mCores; }
    QString loadText() const { return mLoadText; }
    QVariantList cpuHistory() const { return mCpuHist; }

    bool boosting() const { return mBoosting; }
    QString lastBoostFreedText() const;
    double lastBoostFreedBytes() const { return static_cast<double>(mLastFreed); }

    bool alertsEnabled() const { return mAlertsEnabled; }
    int cpuAlert() const { return mCpuAlert; }
    int memAlert() const { return mMemAlert; }
    int diskAlert() const { return mDiskAlert; }
    void setAlertsEnabled(bool on);
    void setCpuAlert(int v);
    void setMemAlert(int v);
    void setDiskAlert(int v);

    // Free reclaimable memory (page cache / dentries / inodes). Needs root.
    Q_INVOKABLE void boost();

  signals:
    void metricsChanged();
    void boostingChanged();
    void boostFinished();
    void alertsChanged();

  private slots:
    void refresh();

  private:
    CpuInfo mCpuInfo;
    MemoryInfo mMemoryInfo;
    SystemInfo mSystemInfo;
    QTimer mTimer;

    void checkAlerts();
    void notify(const QString &title, const QString &body);

    int mCpuPercent = 0;
    quint64 mRootUsed = 0;
    quint64 mRootSize = 0;
    QString mCpuClockText;
    QString mUptimeText;
    QString mLoadText;
    QVariantList mCores;
    QVariantList mCpuHist;
    static const int kCpuHistory = 60;
    bool mBoosting = false;
    quint64 mMemBefore = 0;
    quint64 mLastFreed = 0;

    bool mAlertsEnabled = false;
    int mCpuAlert = 90;
    int mMemAlert = 90;
    int mDiskAlert = 90;
    bool mCpuAlerting = false;
    bool mMemAlerting = false;
    bool mDiskAlerting = false;
};

#endif // SYSTEMCONTROLLER_H

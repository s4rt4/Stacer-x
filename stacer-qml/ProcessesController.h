#ifndef PROCESSESCONTROLLER_H
#define PROCESSESCONTROLLER_H

#include <QAbstractListModel>
#include <QTimer>

#include "Info/process_info.h"
#include "Info/process.h"

// List model of running processes, exposed to QML as `processes`.
// Sorted by CPU usage (desc). Refreshes on a timer only while active.
class ProcessesController : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(int count READ count NOTIFY countChanged)
    Q_PROPERTY(QString filter READ filter WRITE setFilter NOTIFY filterChanged)

  public:
    enum Roles {
        PidRole = Qt::UserRole + 1,
        CmdRole,
        UserRole,
        CpuRole,
        MemRole,
        NiceRole,
        StateRole,
    };

    explicit ProcessesController(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    int count() const { return mRows.size(); }
    QString filter() const { return mFilter; }
    void setFilter(const QString &filter);

    // Start/stop polling — bound to page visibility to avoid wasting CPU.
    Q_INVOKABLE void setActive(bool active);
    Q_INVOKABLE void refresh();
    Q_INVOKABLE void killProcess(int pid);
    Q_INVOKABLE void setPriority(int pid, int nice);

  signals:
    void countChanged();
    void filterChanged();

  private:
    void applyFilter();

    ProcessInfo mProcessInfo;
    QList<Process> mAll;
    QList<Process> mRows;
    QString mFilter;
    QTimer mTimer;
    QString mCurrentUser;
};

#endif // PROCESSESCONTROLLER_H

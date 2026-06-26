#ifndef HOSTSCONTROLLER_H
#define HOSTSCONTROLLER_H

#include <QAbstractListModel>

// /etc/hosts editor exposed to QML as `hosts`. Reads are unprivileged;
// writes go through an elevated copy. Toggling comments/uncomments a line.
class HostsController : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(int count READ count NOTIFY countChanged)
    Q_PROPERTY(bool busy READ busy NOTIFY busyChanged)

  public:
    enum Roles {
        IpRole = Qt::UserRole + 1,
        HostRole,
        EnabledRole,
    };

    explicit HostsController(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    int count() const { return mEntries.size(); }
    bool busy() const { return mBusy; }

    Q_INVOKABLE void setActive(bool active);
    Q_INVOKABLE void reload();
    Q_INVOKABLE void toggle(int index);
    Q_INVOKABLE void removeEntry(int index);
    Q_INVOKABLE void addEntry(const QString &ip, const QString &hostname);

  signals:
    void countChanged();
    void busyChanged();

  private:
    struct Entry {
        int lineIndex;
        QString ip;
        QString host;
        bool enabled;
    };

    void parse();
    void writeAndReload(const QStringList &lines);
    void setBusy(bool busy);

    QStringList mLines;
    QList<Entry> mEntries;
    bool mBusy = false;
    bool mLoaded = false;
};

#endif // HOSTSCONTROLLER_H

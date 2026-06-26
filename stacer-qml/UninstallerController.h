#ifndef UNINSTALLERCONTROLLER_H
#define UNINSTALLERCONTROLLER_H

#include <QAbstractListModel>
#include <QSet>

// Installed packages as a QML list model (`uninstaller`). Lists via the
// detected package manager; removal is elevated. Scan/remove run off-thread.
class UninstallerController : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(int count READ count NOTIFY countChanged)
    Q_PROPERTY(int total READ total NOTIFY countChanged)
    Q_PROPERTY(int selectedCount READ selectedCount NOTIFY selectionChanged)
    Q_PROPERTY(bool busy READ busy NOTIFY busyChanged)
    Q_PROPERTY(QString filter READ filter WRITE setFilter NOTIFY filterChanged)
    Q_PROPERTY(QString manager READ manager CONSTANT)
    Q_PROPERTY(bool removeConfig READ removeConfig WRITE setRemoveConfig NOTIFY removeConfigChanged)

  public:
    enum Roles {
        NameRole = Qt::UserRole + 1,
        SelectedRole,
    };

    explicit UninstallerController(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    int count() const { return mRows.size(); }
    int total() const { return mAll.size(); }
    int selectedCount() const { return mSelected.size(); }
    bool busy() const { return mBusy; }
    QString filter() const { return mFilter; }
    void setFilter(const QString &filter);
    QString manager() const { return mManager; }
    bool removeConfig() const { return mRemoveConfig; }
    void setRemoveConfig(bool on);

    Q_INVOKABLE void setActive(bool active);
    Q_INVOKABLE void reload();
    Q_INVOKABLE void toggle(const QString &name);
    Q_INVOKABLE void clearSelection();
    Q_INVOKABLE void removeSelected();
    // Preview the user config/cache folders that match the current selection.
    Q_INVOKABLE void requestLeftovers();
    // Remove orphaned dependencies (dnf/apt autoremove).
    Q_INVOKABLE void autoremove();

  signals:
    void countChanged();
    void selectionChanged();
    void busyChanged();
    void filterChanged();
    void removeConfigChanged();
    void leftoversReady(const QVariantList &items);

  private:
    void setBusy(bool busy);
    void setPackages(const QStringList &packages);
    void applyFilter();

    QStringList mAll;
    QStringList mRows;
    QSet<QString> mSelected;
    QString mFilter;
    QString mManager;
    bool mBusy = false;
    bool mLoaded = false;
    bool mRemoveConfig = false;
};

#endif // UNINSTALLERCONTROLLER_H

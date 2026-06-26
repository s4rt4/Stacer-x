#ifndef STARTUPCONTROLLER_H
#define STARTUPCONTROLLER_H

#include <QAbstractListModel>
#include <QFileSystemWatcher>

// Autostart entries (~/.config/autostart/*.desktop) as a QML list model
// (`startup`). All operations are user-level — no elevation needed.
class StartupController : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(int count READ count NOTIFY countChanged)

  public:
    enum Roles {
        NameRole = Qt::UserRole + 1,
        EnabledRole,
        PathRole,
    };

    explicit StartupController(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    int count() const { return mRows.size(); }

    Q_INVOKABLE void setActive(bool active);
    Q_INVOKABLE void reload();
    Q_INVOKABLE void setEnabled(const QString &path, bool enabled);
    Q_INVOKABLE void removeApp(const QString &path);

  signals:
    void countChanged();

  private:
    struct Entry {
        QString name;
        bool enabled;
        QString path;
    };

    QString mAutostartPath;
    QList<Entry> mRows;
    QFileSystemWatcher mWatcher;
};

#endif // STARTUPCONTROLLER_H

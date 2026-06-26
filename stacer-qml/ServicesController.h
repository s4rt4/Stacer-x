#ifndef SERVICESCONTROLLER_H
#define SERVICESCONTROLLER_H

#include <QAbstractListModel>

#include "Tools/service_tool.h"

// systemd services as a QML list model (`services`). The scan is heavy
// (a subprocess per service), so load() runs off the main thread.
class ServicesController : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(int count READ count NOTIFY countChanged)
    Q_PROPERTY(bool loading READ loading NOTIFY loadingChanged)
    Q_PROPERTY(QString filter READ filter WRITE setFilter NOTIFY filterChanged)

  public:
    enum Roles {
        NameRole = Qt::UserRole + 1,
        DescRole,
        ActiveRole,   // running now
        EnabledRole,  // starts on boot
    };

    explicit ServicesController(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    int count() const { return mRows.size(); }
    bool loading() const { return mLoading; }
    QString filter() const { return mFilter; }
    void setFilter(const QString &filter);

    // Load once when the page first appears.
    Q_INVOKABLE void setActive(bool active);
    Q_INVOKABLE void reload();
    Q_INVOKABLE void toggleActive(const QString &name, bool running);
    Q_INVOKABLE void toggleEnabled(const QString &name, bool enabled);

  signals:
    void countChanged();
    void loadingChanged();
    void filterChanged();

  private:
    void setServices(const QList<Service> &services);
    void setLoading(bool loading);
    void updateRow(const QString &name, bool active, bool enabled);
    void applyFilter();

    QList<Service> mAll;
    QList<Service> mRows;
    QString mFilter;
    bool mLoading = false;
    bool mLoaded = false;
};

#endif // SERVICESCONTROLLER_H

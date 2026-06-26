#ifndef CLEANERCONTROLLER_H
#define CLEANERCONTROLLER_H

#include <QAbstractListModel>

// System cleaner: scannable junk categories (caches, trash, logs, crash
// reports) exposed to QML as `cleaner`. Scanning and cleaning run off-thread.
class CleanerController : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(bool busy READ busy NOTIFY busyChanged)
    Q_PROPERTY(bool scanned READ scanned NOTIFY scannedChanged)
    Q_PROPERTY(QString totalSelectedText READ totalSelectedText NOTIFY changed)

  public:
    enum Roles {
        KeyRole = Qt::UserRole + 1,
        LabelRole,
        IconRole,
        SizeTextRole,
        SelectedRole,
    };

    explicit CleanerController(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    bool busy() const { return mBusy; }
    bool scanned() const { return mScanned; }
    QString totalSelectedText() const;

    Q_INVOKABLE void setActive(bool active);
    Q_INVOKABLE void scan();
    Q_INVOKABLE void clean();
    Q_INVOKABLE void setSelected(int index, bool selected);

    // Off-thread listing of what a category would remove → detailsReady.
    Q_INVOKABLE void requestDetails(const QString &key);

  signals:
    void busyChanged();
    void scannedChanged();
    void changed();
    void detailsReady(const QString &key, const QVariantList &items);

  private:
    struct Category {
        QString key;
        QString label;
        QString icon;
        bool needsSudo;
        bool selected;
        quint64 sizeBytes;
    };

    void setBusy(bool busy);
    void applySizes(const QList<quint64> &sizes);

    QList<Category> mCats;
    bool mBusy = false;
    bool mScanned = false;
};

#endif // CLEANERCONTROLLER_H

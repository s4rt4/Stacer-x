#include "ServicesController.h"

#include <algorithm>

#include <QtConcurrent>

ServicesController::ServicesController(QObject *parent) : QAbstractListModel(parent)
{
}

int ServicesController::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid())
        return 0;
    return mRows.size();
}

QVariant ServicesController::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= mRows.size())
        return QVariant();

    const Service &s = mRows.at(index.row());
    switch (role) {
        case NameRole:    return s.name;
        case DescRole:    return s.description;
        case ActiveRole:  return s.active;
        case EnabledRole: return s.status;
    }
    return QVariant();
}

QHash<int, QByteArray> ServicesController::roleNames() const
{
    return {
        { NameRole,    "name" },
        { DescRole,    "description" },
        { ActiveRole,  "active" },
        { EnabledRole, "enabled" },
    };
}

void ServicesController::setActive(bool active)
{
    if (active && !mLoaded)
        reload();
}

void ServicesController::reload()
{
    if (mLoading)
        return;

    setLoading(true);

    (void) QtConcurrent::run([this]() {
        QList<Service> list = ServiceTool::getServicesWithSystemctl();
        std::sort(list.begin(), list.end(),
                  [](const Service &a, const Service &b) { return a.name < b.name; });
        QMetaObject::invokeMethod(
            this, [this, list]() { setServices(list); }, Qt::QueuedConnection);
    });
}

void ServicesController::setServices(const QList<Service> &services)
{
    mAll = services;
    mLoaded = true;
    setLoading(false);
    applyFilter();
}

void ServicesController::setFilter(const QString &filter)
{
    const QString f = filter.trimmed();
    if (f == mFilter)
        return;
    mFilter = f;
    emit filterChanged();
    applyFilter();
}

void ServicesController::applyFilter()
{
    QList<Service> filtered;
    if (mFilter.isEmpty()) {
        filtered = mAll;
    } else {
        for (const Service &s : mAll) {
            if (s.name.contains(mFilter, Qt::CaseInsensitive)
                || s.description.contains(mFilter, Qt::CaseInsensitive))
                filtered.append(s);
        }
    }

    beginResetModel();
    mRows = filtered;
    endResetModel();
    emit countChanged();
}

void ServicesController::setLoading(bool loading)
{
    if (mLoading == loading)
        return;
    mLoading = loading;
    emit loadingChanged();
}

void ServicesController::updateRow(const QString &name, bool active, bool enabled)
{
    // Update the source list…
    for (int i = 0; i < mAll.size(); ++i) {
        if (mAll.at(i).name == name) {
            mAll[i].active = active;
            mAll[i].status = enabled;
            break;
        }
    }
    // …and the currently visible row, if present.
    for (int i = 0; i < mRows.size(); ++i) {
        if (mRows.at(i).name == name) {
            mRows[i].active = active;
            mRows[i].status = enabled;
            emit dataChanged(index(i), index(i), { ActiveRole, EnabledRole });
            break;
        }
    }
}

void ServicesController::toggleActive(const QString &name, bool running)
{
    const QString unit = name + ".service";
    (void) QtConcurrent::run([this, name, unit, running]() {
        ServiceTool::changeServiceActive(unit, running);
        bool active = ServiceTool::serviceIsActive(unit);
        bool enabled = ServiceTool::serviceIsEnabled(unit);
        QMetaObject::invokeMethod(
            this, [this, name, active, enabled]() { updateRow(name, active, enabled); },
            Qt::QueuedConnection);
    });
}

void ServicesController::toggleEnabled(const QString &name, bool enabled)
{
    const QString unit = name + ".service";
    (void) QtConcurrent::run([this, name, unit, enabled]() {
        ServiceTool::changeServiceStatus(unit, enabled);
        bool active = ServiceTool::serviceIsActive(unit);
        bool isEnabled = ServiceTool::serviceIsEnabled(unit);
        QMetaObject::invokeMethod(
            this, [this, name, active, isEnabled]() { updateRow(name, active, isEnabled); },
            Qt::QueuedConnection);
    });
}

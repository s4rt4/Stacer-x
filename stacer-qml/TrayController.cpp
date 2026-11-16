#include "TrayController.h"

#include <QAction>
#include <QCoreApplication>
#include <QIcon>
#include <QWindow>

TrayController::TrayController(QObject *parent) : QObject(parent)
{
    mShowAction = mMenu.addAction(QString());
    connect(mShowAction, &QAction::triggered, this, &TrayController::showWindow);
    mMenu.addSeparator();
    mQuitAction = mMenu.addAction(QString());
    connect(mQuitAction, &QAction::triggered, this, &TrayController::quit);
    mIcon.setIcon(QIcon(QStringLiteral(":/qt/qml/Stacer/qml/stacer-logo.svg")));
    mIcon.setToolTip(QStringLiteral("Stacer-X"));
    mIcon.setContextMenu(&mMenu);
    connect(&mIcon, &QSystemTrayIcon::activated, this, [this](QSystemTrayIcon::ActivationReason reason) {
        if (reason == QSystemTrayIcon::Trigger || reason == QSystemTrayIcon::DoubleClick)
            showWindow();
    });
    retranslate();
    // Qt registers the icon when a tray becomes available, including if the
    // desktop's tray service starts after this application.
    mIcon.show();
}

void TrayController::setWindow(QWindow *window)
{
    mWindow = window;
}

void TrayController::retranslate()
{
    mShowAction->setText(tr("Show Stacer-X"));
    mQuitAction->setText(tr("Quit"));
}

bool TrayController::hideWindow()
{
    if (!mWindow || !mIcon.isVisible() || !QSystemTrayIcon::isSystemTrayAvailable())
        return false;
    mWindow->hide();
    return true;
}

void TrayController::showWindow()
{
    if (!mWindow)
        return;
    mWindow->showNormal();
    mWindow->raise();
    mWindow->requestActivate();
}

void TrayController::quit()
{
    mQuitting = true;
    emit quittingChanged();
    QCoreApplication::quit();
}

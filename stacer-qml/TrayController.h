#ifndef TRAYCONTROLLER_H
#define TRAYCONTROLLER_H

#include <QMenu>
#include <QObject>
#include <QPointer>
#include <QSystemTrayIcon>

class QWindow;

// Keeps the window accessible while it is hidden, without relying on a tray
// icon on desktops that do not provide one.
class TrayController : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool quitting READ quitting NOTIFY quittingChanged)

  public:
    explicit TrayController(QObject *parent = nullptr);
    void setWindow(QWindow *window);
    void retranslate();
    bool quitting() const { return mQuitting; }

    Q_INVOKABLE bool hideWindow();
    Q_INVOKABLE void showWindow();
    Q_INVOKABLE void quit();

  signals:
    void quittingChanged();

  private:
    QPointer<QWindow> mWindow;
    QMenu mMenu;
    QAction *mShowAction = nullptr;
    QAction *mQuitAction = nullptr;
    QSystemTrayIcon mIcon;
    bool mQuitting = false;
};

#endif // TRAYCONTROLLER_H

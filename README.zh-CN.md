# Stacer-X 中文说明

Stacer-X 是基于 Qt Quick 的 Linux 系统监控与管理工具，提供系统资源、进程、服务和启动项管理。
项目地址：[s4rt4/Stacer-x](https://github.com/s4rt4/Stacer-x)。

## 本次更新

- 在“设置 → 语言”中切换简体中文和 English，切换立即生效，并在下次启动时保留。
  首次运行时根据系统语言选择；应用名、服务名和系统信息保留系统提供的内容。
- 默认关闭窗口后隐藏到系统托盘，继续运行资源监控及已启用的告警。可通过托盘图标或
  “显示 Stacer-X”恢复窗口，通过托盘菜单“退出”完全退出。
- 在“设置 → 关闭时隐藏到系统托盘”中可以关闭后台驻留。如果桌面没有可用托盘，
  关闭窗口会正常退出，避免窗口被隐藏后无法恢复。GNOME 需要可用的托盘或 AppIndicator 扩展。

## 编译

需要 Qt 6.5 或更新版本，以及 Qt Quick、Widgets、Linguist Tools、CMake 和构建工具。
Ubuntu 22.04 标准软件源中的 Qt 6 版本较旧，需要另行准备符合要求的 Qt SDK。
构建方式及完整依赖请参见 [英文 README](README.md)。

项目许可证见 [LICENSE](LICENSE)。

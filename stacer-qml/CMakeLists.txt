cmake_minimum_required(VERSION 3.16)

# QML frontend (PC Manager style). Built as a separate executable `stacer-x`
# alongside the legacy Widgets `stacer`, reusing stacer-core as-is.
find_package(Qt6 REQUIRED COMPONENTS Core Gui Qml Quick QuickControls2 Concurrent Network Widgets LinguistTools)

qt_standard_project_setup(REQUIRES 6.5)

qt_add_executable(stacer-x
  main.cpp
  SystemController.cpp
  SystemController.h
  ProcessesController.cpp
  ProcessesController.h
  ServicesController.cpp
  ServicesController.h
  StartupController.cpp
  StartupController.h
  CleanerController.cpp
  CleanerController.h
  ResourcesController.cpp
  ResourcesController.h
  SettingsController.cpp
  SettingsController.h
  UninstallerController.cpp
  UninstallerController.h
  HostsController.cpp
  HostsController.h
  TrayController.cpp
  TrayController.h
)

# Theme is a QML singleton (must be declared before qt_add_qml_module).
set_source_files_properties(qml/Theme.qml PROPERTIES QT_QML_SINGLETON_TYPE TRUE)

file(GLOB STACERX_ICONS "${CMAKE_CURRENT_SOURCE_DIR}/qml/icons/*.svg")
foreach(_icon ${STACERX_ICONS})
  file(RELATIVE_PATH _alias "${CMAKE_CURRENT_SOURCE_DIR}" "${_icon}")
  set_source_files_properties("${_icon}" PROPERTIES QT_RESOURCE_ALIAS "${_alias}")
endforeach()

qt_add_qml_module(stacer-x
  URI Stacer
  VERSION 1.0
  QML_FILES
    qml/Main.qml
    qml/Theme.qml
    qml/components/IconImage.qml
    qml/components/Card.qml
    qml/components/NavRail.qml
    qml/components/NavItem.qml
    qml/components/AccentButton.qml
    qml/components/BoostMetric.qml
    qml/components/HeroBanner.qml
    qml/components/FeatureTile.qml
    qml/components/TitleBar.qml
    qml/components/WinButton.qml
    qml/components/Toggle.qml
    qml/components/Logo.qml
    qml/components/SearchField.qml
    qml/components/NumberStepper.qml
    qml/components/Sparkline.qml
    qml/components/ResourceChart.qml
    qml/components/PieChart.qml
    qml/pages/DashboardPage.qml
    qml/pages/ProcessesPage.qml
    qml/pages/ServicesPage.qml
    qml/pages/StartupPage.qml
    qml/pages/CleanerPage.qml
    qml/pages/ResourcesPage.qml
    qml/pages/DiskPage.qml
    qml/pages/AboutPage.qml
    qml/pages/SettingsPage.qml
    qml/pages/UninstallerPage.qml
    qml/pages/HostsPage.qml
    qml/pages/PlaceholderPage.qml
  RESOURCES
    ${STACERX_ICONS}
    qml/stacer-logo.svg
)

target_include_directories(stacer-x PRIVATE "${PROJECT_ROOT}/stacer-core")

target_link_libraries(stacer-x PRIVATE
  stacer-core
  Qt6::Core Qt6::Gui Qt6::Qml Qt6::Quick Qt6::QuickControls2 Qt6::Concurrent Qt6::Network Qt6::Widgets
)

# Keep the translation catalog inside the executable.
set(STACER_ZH_QM "${CMAKE_CURRENT_BINARY_DIR}/stacer-x_zh_CN.qm")
add_custom_command(OUTPUT "${STACER_ZH_QM}"
  COMMAND Qt6::lrelease "${CMAKE_CURRENT_SOURCE_DIR}/translations/stacer-x_zh_CN.ts" -qm "${STACER_ZH_QM}"
  DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/translations/stacer-x_zh_CN.ts"
  VERBATIM)
qt_add_resources(stacer-x translations PREFIX /i18n
  BASE "${CMAKE_CURRENT_BINARY_DIR}" FILES "${STACER_ZH_QM}")

install(
  TARGETS stacer-x
  RUNTIME DESTINATION bin
)

# Desktop integration — menu entry + themed icon. The .desktop basename and the
# icon name both match QGuiApplication::setDesktopFileName("stacer-x") in main.cpp,
# so the launcher/dock shows the brand logo.
install(
  FILES "${PROJECT_ROOT}/desktop/stacer-x.desktop"
  DESTINATION share/applications
)

install(
  FILES "${PROJECT_ROOT}/stacer-logo.svg"
  DESTINATION share/icons/hicolor/scalable/apps
  RENAME stacer-x.svg
)

# Single self-contained binary + a couple of data files — no separate debuginfo.
%global debug_package %{nil}
%global _pkgbuilddir %{_builddir}/%{name}-%{version}/build-pkg

Name:           stacer-x
Version:        1.7.0
Release:        1%{?dist}
Summary:        Linux system optimizer with a PC Manager-style Qt Quick UI

License:        GPL-3.0-or-later
URL:            https://github.com/s4rt4/Stacer-x
Source0:        %{name}-%{version}.tar.gz

BuildRequires:  cmake
BuildRequires:  gcc-c++
BuildRequires:  qt6-qtbase-devel
BuildRequires:  qt6-qtdeclarative-devel

Requires:       qt6-qtbase
Requires:       qt6-qtbase-gui
Requires:       qt6-qtdeclarative
# Qt5Compat.GraphicalEffects (icon recoloring) is loaded at runtime by the
# QML engine — a hard runtime dependency even though it isn't linked.
Requires:       qt6-qt5compat
# SVG image plugin for the Lucide icon set and the brand logo.
Requires:       qt6-qtsvg
# pkexec for privileged actions (clean root caches, edit /etc/hosts, uninstall…).
Requires:       polkit
# notify-send for resource alerts.
Requires:       libnotify
Requires:       hicolor-icon-theme

%description
Stacer-X is a Qt Quick (QML) front-end for the Stacer Linux system optimizer,
restyled after Microsoft PC Manager. Monitor CPU, memory, disk and network in
real time; manage systemd services, startup applications, running processes and
the /etc/hosts file; clean junk caches and uninstall packages.

%prep
%autosetup -n %{name}-%{version}

%build
cmake -S . -B %{_pkgbuilddir} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=%{_prefix} \
    -DBUILD_LEGACY_STACER=OFF
cmake --build %{_pkgbuilddir} -j $(nproc)

%install
rm -rf %{buildroot}
DESTDIR=%{buildroot} cmake --install %{_pkgbuilddir}

%files
%license LICENSE
%doc README.md
%{_bindir}/stacer-x
%{_datadir}/applications/stacer-x.desktop
%{_datadir}/icons/hicolor/scalable/apps/stacer-x.svg

%changelog
* Sun Jun 28 2026 s4rt4 <vinvan83@gmail.com> - 1.7.0-1
- Initial Stacer-X package: Qt Quick front-end only (BUILD_LEGACY_STACER=OFF).

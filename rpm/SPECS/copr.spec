Name:           stacer
Version:        1.6.3
Release:        1%{?dist}
Summary:        Linux system optimizer and monitoring

License:        GPL-3.0
URL:            https://github.com/QuentiumYT/Stacer
Source0:        %{url}/archive/v%{version}/%{name}-%{version}.tar.gz

BuildRequires:  cmake
BuildRequires:  desktop-file-utils
BuildRequires:  gcc-c++
BuildRequires:  ninja-build

BuildRequires:  cmake(Qt6Core)
BuildRequires:  cmake(Qt6Gui)
BuildRequires:  cmake(Qt6Widgets)
BuildRequires:  cmake(Qt6LinguistTools)
BuildRequires:  cmake(Qt6Charts)
BuildRequires:  cmake(Qt6Svg)
BuildRequires:  cmake(Qt6Concurrent)
BuildRequires:  cmake(Qt6Network)

Requires:       hicolor-icon-theme
Requires:       qt6-qttools%{?_isa}
Requires:       qt6-qtcharts%{?_isa}
Requires:       qt6-svg%{?_isa}

%description
Monitor your system (CPU, memory, disk) in a graphical application (Qt).
Change and monitor your services. Summarizes basic system information and
can show network download/upload speeds/totals.

%prep
%autosetup -n Stacer-%{version}

%build
%cmake -G Ninja \
    -DCMAKE_INSTALL_PREFIX=%{_prefix} \
    -DCMAKE_BUILD_TYPE=Release

%cmake_build

# Build translations
lrelease-qt6 %{name}/%{name}.pro

%install
%cmake_install

%find_lang %{name} --with-qt

%check
desktop-file-validate %{buildroot}%{_datadir}/applications/*.desktop

%files -f %{name}.lang
%license LICENSE
%doc README.md
%{_bindir}/%{name}
%{_datadir}/applications/*.desktop
%{_datadir}/icons/hicolor/*/*/*.png
%{_datadir}/icons/hicolor/scalable/apps/*.svg
%{_datadir}/metainfo/fr.quentium.%{name}.metainfo.xml

# Translations files which rpm macros cant handle
%dir %{_datadir}/%{name}/translations/
%{_datadir}/%{name}/translations/stacer_zh-cn.qm
%{_datadir}/%{name}/translations/stacer_zh-tw.qm

%changelog
* Mon Apr 13 2026 Quentin Lienhardt <pro@quentium.fr> - 1.6.3-1
- Initial package republish

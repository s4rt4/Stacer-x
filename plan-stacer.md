# Stacer Reborn — Project Plan (QML)

> Brief untuk coding agent. Tujuan: menghidupkan kembali Stacer (Linux system optimizer)
> dengan tampilan modern bergaya **Microsoft PC Manager (Fluent Design, dark)**.
>
> **KEPUTUSAN FINAL (2026-06-25): lapisan UI ditulis ulang ke Qt Quick / QML.**
> Pendekatan QSS lama dibatalkan — lihat §0. Backend C++ (`stacer-core`) dipakai apa adanya.

---

## 0. Kenapa pindah dari QSS ke QML (konteks keputusan)

Iterasi awal memakai re-style **QSS** pada Stacer (Qt Widgets). Pendekatan itu **dibatalkan** karena
plafon QSS terlalu rendah untuk ambisi redesign layout & UI yang besar:

- ❌ Tidak ada animasi/transisi (hover/checked berganti seketika).
- ❌ Tidak ada `box-shadow`/blur/elevasi (harus `QGraphicsDropShadowEffect` per-widget di C++).
- ❌ Tidak bisa swap ikon per-state (`:checked` mengabaikan `qproperty-icon` — terbukti gagal saat eksperimen).
- ❌ Layout bukan wilayah QSS sama sekali (ada di `.ui`/C++); gauge dilukis manual via QPainter.
- ❌ Widget bentuk custom, kurva, gradient lintas-platform tidak andal.

**QML/Qt Quick** memberi kendali penuh atas layout (deklaratif), animasi first-class, komponen custom,
dan look modern — sambil tetap memakai logika sistem yang sudah ada.

**Yang bisa diselamatkan dari kerja QSS:** token warna, peta ikon nav, dan pemahaman struktur halaman
(lihat `findings.md`). Token warna PC Manager tinggal diport ke QML singleton `Theme`.

**Aset kunci yang memungkinkan QML:** `stacer-core` (semua logika sistem) **sudah terpisah** dari UI.
Jadi kita menulis ulang **lapisan tampilan saja**, bukan backend.

---

## 1. Konteks & keputusan strategis

| Hal | Keputusan | Alasan |
|---|---|---|
| Basis kode | **Fork `QuentiumYT/Stacer`** (Qt6, CMake, Deb822) | Repo asli `oguzhaninan/Stacer` abandoned. Fork sudah Qt6. |
| Backend | **Pakai `stacer-core` apa adanya** (C++) | Logika CPU/RAM/disk/net/proses/services/packages sudah ada & terpisah. Jangan tulis ulang. |
| Frontend | **Tulis ulang ke Qt Quick / QML** (Qt Quick Controls 2) | Kendali penuh layout + animasi + komponen custom = wajib untuk redesign besar. |
| UI lama (Widgets) | **Pensiun bertahap** | Dirujuk sebagai referensi perilaku, lalu dihapus saat halaman QML setara siap. |
| Bridge core→QML | **QObject controller per domain**, di-expose ke QML | QML mengikat ke properti/sinyal/slot C++. Sebagian glue saat ini ada di Widget pages → diekstrak ke controller. |
| Animasi/Mica | **Animasi: in scope (QML).** Mica/acrylic: out of scope (tak portabel di Linux). | |

**Lisensi:** Stacer GPL. Modifikasi & turunan **wajib tetap GPL & open-source**. Pertahankan header lisensi & `LICENSE`.

---

## 2. Repositori (sudah dilakukan)

Sudah di-clone & terhubung di working dir:
- `origin` = `https://github.com/s4rt4/Stacer-x.git` (fork)
- `upstream` = `https://github.com/QuentiumYT/Stacer.git`
- branch `main`. Build baseline (Widgets lama) sudah sukses → lihat `findings.md` §7.

Aturan: kerjakan di branch fitur, mis. `git checkout -b feature/qml-frontend`.
Tarik update upstream nanti: `git fetch upstream && git merge upstream/main` (konflik kemungkinan kecil
karena kita menambah pohon QML baru, bukan mengubah banyak file lama).

---

## 3. Dependensi (Fedora — sudah terverifikasi terpasang)

QML stack di mesin dev sudah ada: `qt6-qtdeclarative(-devel)` (termasuk QtQuick.Controls),
`qt6-qtcharts(-devel)`, `qt6-qt5compat`, `qt6-qtshadertools`, `qt6-qtquicktimeline`, `qt6-qtquick3d`.
Untuk grafik di QML, pilih salah satu: **QtCharts (QML)** atau **Qt Graphs** (`qt6-qtgraphs-devel`, tersedia).

Debian/Ubuntu (untuk packaging nanti): `qml6-module-qtquick*`, `qt6-declarative-dev`,
`qml6-module-qtquick-controls`, `qml6-module-qtcharts` (atau qtgraphs), plus dependensi build lama.

---

## 4. Arsitektur target

```
stacer-core/                 # C++ backend — DIPAKAI APA ADANYA (info + tools)
  Info/  cpu_info, memory_info, disk_info, network_info, process_info, system_info
  Tools/ service_tool, package_tool, apt_source_tool, gnome_settings_tool

stacer/                      # lapisan baru (QML + bridge C++ tipis)
  backend/                   # QObject controller yang membungkus stacer-core, di-expose ke QML
    DashboardController, CleanerController, ServicesController,
    ProcessesController, StartupController, ResourcesController,
    UninstallerController, SettingsController
  qml/
    Main.qml                 # window + sidebar + StackView/Loader halaman
    Theme.qml (singleton)    # token warna/spacing/radius/font (port dari ui-guideline §Color)
    components/              # Card.qml, NavRail.qml, NavItem.qml, MetricTile.qml,
                            #   AccentButton.qml, HeroBanner.qml, Gauge.qml, ...
    pages/                   # DashboardPage.qml, CleanerPage.qml, ... (1:1 dgn controller)
    icons/                   # SVG (folder `icon/` di root — set Lucide)
  main.cpp                   # QGuiApplication + QQmlApplicationEngine, daftar controller
  qml.qrc / qt_add_qml_module
```

**Pola bridge:** tiap controller meng-expose `Q_PROPERTY` (data untuk binding), `Q_INVOKABLE`
(aksi: scan, clean, start/stop service, kill process, uninstall), dan sinyal (update async via
`QtConcurrent`/timer). QML hanya konsumen — tanpa logika sistem di QML.

---

## 5. Implementasi (fase per fase)

> Acuan visual: `mockup-stacer.html` & `ui-guideline-stacer.md`. Peta struktur lama: `findings.md`.

### Fase A — Skeleton QML + build
- Tambah target QML di CMake (`qt_add_qml_module`, link `Qt6::Quick Qt6::QuickControls2 Qt6::Qml`).
- `main.cpp`: `QQmlApplicationEngine` memuat `Main.qml` (window kosong + Theme singleton).
- **Acceptance:** window QML kosong bergaya dark (warna `Theme.bg`) jalan berdampingan/menggantikan entry lama.

### Fase B — Design system (Theme + komponen inti)
- `Theme.qml`: port token dari `ui-guideline-stacer.md` §Color/Typography/Layout.
- Komponen: `Card`, `AccentButton`, `NavRail`+`NavItem`, `MetricTile`, `HeroBanner`.
- **Acceptance:** halaman demo menampilkan kartu, tombol aksen, sidebar — cocok dengan mockup, dengan
  animasi hover/checked halus.

### Fase C — Sidebar + shell navigasi
- `NavRail` (ikon SVG + label, item aktif highlight + animasi), `StackView`/`Loader` untuk halaman.
- Ikon: SVG dari folder `icon/` (Lucide). Warna ikut state via `Theme` (binding warna, bukan file terpisah).
- **Acceptance:** pindah halaman mulus, item aktif jelas (atasi masalah ikon-state lama secara native QML).

### Fase D — Dashboard (pilot, end-to-end)
- `DashboardController` bungkus `cpu_info/memory_info/disk_info/network_info/system_info`.
- `Gauge.qml` (Canvas/Shape) untuk CPU/RAM/Disk; kartu System info; kartu Download/Upload.
- **Acceptance:** Dashboard menampilkan data live nyata via controller; visual sesuai mockup.

### Fase E — Halaman sisa
- Cleaner, Services, Processes, Startup, Resources, Uninstaller (+ APT/Gnome kondisional) — masing-masing
  controller + page QML. Reuse `service_tool/package_tool/process_info/...`.
- **Acceptance:** seluruh fitur lama berfungsi via UI QML; tak ada regresi fungsional.

### Fase F — Poles & pensiunkan Widgets
- Animasi transisi halaman, elevasi/shadow (efek QML), font (Inter/Segoe fallback), i18n.
- Hapus kode Widget lama (`stacer/Pages/*` Widgets, `app.ui`, tema QSS) setelah QML setara.
- **Acceptance:** build bersih tanpa Widgets; konsisten di KDE & GNOME.

---

## 6. Definition of Done

- [ ] Build sukses dari bersih (Qt6 + QML) di Fedora & Debian/Ubuntu.
- [ ] Semua halaman ada di QML, mengikat ke `stacer-core` via controller; tak ada regresi fungsional.
- [ ] Visual sesuai `ui-guideline-stacer.md` & `mockup-stacer.html`, dengan animasi.
- [ ] Header lisensi GPL dipertahankan; `LICENSE` tidak diubah.
- [ ] README diperbarui: fork + kredit `oguzhaninan` & `QuentiumYT` + catatan migrasi QML.
- [ ] Screenshot before/after dilampirkan (capture manual; GNOME Wayland blokir capture programatik).

---

## 7. Catatan untuk agent berikutnya

- **Jangan sentuh `stacer-core`** kecuali untuk meng-expose data (mis. tambah getter). Logika sistem berharga.
- **Jangan menaruh logika sistem di QML.** QML = view; semua perintah Linux/parsing lewat controller C++.
- Baca `findings.md` dulu — ada peta kelas halaman lama, objectName, dan lokasi logika untuk dijadikan acuan controller.
- Sisa artefak QSS (`stacer/static/themes/pc-manager/*`, perubahan di `setting_manager.cpp`, `static.qrc`,
  `themes.json`) adalah eksperimen lama — boleh dipakai sebagai **referensi warna/ikon** lalu dibersihkan di Fase F.
  Folder `icon/` (SVG Lucide) di root adalah sumber ikon untuk QML.
- Commit kecil & deskriptif; satu fase per PR bila memungkinkan.
- Screenshot verifikasi: minta user (GNOME Wayland memblokir grim & D-Bus screenshot non-interaktif).

---

## 8. Out of scope

- Efek **Mica/acrylic** (blur tembus wallpaper) — tidak portabel di Linux.
- Fitur fungsional baru — proyek fokus migrasi tampilan; tambah fitur di iterasi terpisah.

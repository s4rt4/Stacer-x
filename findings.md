# Findings — Pemetaan Kode Stacer

> Hasil inspeksi repo fork `s4rt4/Stacer-x` (upstream `QuentiumYT/Stacer`), Qt6.

> ⚠️ **STATUS (2026-06-25): proyek pivot ke QML.** Lihat `plan-stacer.md` §0.
> Bagian QSS di bawah (§1–§2, §6) kini **referensi historis** — sistem tema QSS lama dan tema eksperimen
> `pc-manager` tidak lagi jadi jalur utama. **Yang tetap relevan untuk QML:**
> - **§4 Sidebar** & **§3 daftar halaman** — peta struktur UI yang akan ditiru di QML.
> - **§5 Pemisahan logika/UI** — `stacer-core` terpisah = fondasi bridge controller→QML.
> - **§7 Status build** — toolchain & dependensi (QML stack sudah terpasang, lihat `plan-stacer.md` §3).
>   Kelas di `stacer-core/Info` & `stacer-core/Tools` adalah backend yang akan di-expose ke QML.

---

## 1. File stylesheet (QSS) — *historis, jalur QSS dibatalkan*

Sistem tema berbasis **folder per-tema + substitusi placeholder**, bukan satu file QSS statis.

| Item | Path |
|---|---|
| Tema default (dark) | `stacer/static/themes/default/style/style.qss` (1077 baris) |
| Tema light | `stacer/static/themes/light/style/style.qss` |
| Token warna default | `stacer/static/themes/default/style/values.ini` |
| Daftar tema | `stacer/static/themes.json` |
| Resource bundle | `stacer/static.qrc` (semua di-embed via Qt resource `:/static/...`) |
| Ikon sidebar (PNG!) | `stacer/static/themes/default/img/sidebar-icons/*.png` |

**Cara kerja tema (penting):**
`values.ini` mendefinisikan placeholder seperti `@globalBackground=#212f3c`. Saat runtime,
`AppManager::updateStylesheet()` membaca `style.qss` lalu **replace setiap `@key` dengan nilainya**.
Jadi mengganti warna global cukup lewat `values.ini`, tidak perlu sentuh QSS.

Token yang sudah ada di `values.ini` default:
`@pageContent @sidebar @globalBackground @globalHoverBackground @globalText @labelText`
`@infoText @buttonText @buttonBackground @buttonHoverBackground @successText @errorText` dll.

---

## 2. Titik pemuatan QSS (`setStyleSheet`)

| Lokasi | Peran |
|---|---|
| `stacer/Managers/app_manager.cpp:102` | Baca `style.qss` tema aktif |
| `stacer/Managers/app_manager.cpp:104-110` | Substitusi `@token` → nilai dari `values.ini` |
| `stacer/Managers/app_manager.cpp:113-124` | Terapkan offset ukuran font (regex `font-size:Npt`) |
| `stacer/Managers/app_manager.cpp:126` | **`qApp->setStyleSheet(...)`** — penerapan global |
| `stacer/Pages/StartupApps/startup_app_edit.cpp:45` | `setStyleSheet()` lokal pada dialog (pakai konten yang sama) |

`updateStylesheet()` dipanggil dari `app.cpp` saat startup (`AppManager::ins()->updateStylesheet();`).

---

## 3. Kelas halaman & file `.ui`

Direktori: `stacer/Pages/<Nama>/`. Halaman terdaftar di `stacer/app.cpp:56` (`mListPages`).

| Halaman | Kelas / `.ui` |
|---|---|
| Dashboard | `Pages/Dashboard/dashboard_page.ui` (+ `circlebar.ui`, `linebar.ui`) |
| Startup apps | `Pages/StartupApps/startup_apps_page.ui` (+ `startup_app.ui`, `startup_app_edit.ui`) |
| System cleaner | `Pages/SystemCleaner/system_cleaner_page.ui` |
| Search | `Pages/Search/search_page.ui` |
| Services | `Pages/Services/services_page.ui` (+ `service_item.ui`) |
| Processes | `Pages/Processes/processes_page.ui` |
| Uninstaller | `Pages/Uninstaller/uninstallerpage.ui` |
| Resources | `Pages/Resources/resources_page.ui` (+ `history_chart.ui`) — pakai **Qt Charts** |
| Helpers | `Pages/Helpers/helpers_page.ui` (+ `host_manage.ui`) |
| Settings | `Pages/Settings/settings_page.ui` |
| APT source manager | `Pages/AptSourceManager/*` (kondisional: hanya distro berbasis APT) |
| Gnome settings | `Pages/GnomeSettings/*` (kondisional: sesi/distro Ubuntu) |
| Main window | `stacer/app.ui` |

---

## 4. Sidebar (navigasi)

| Aspek | Temuan |
|---|---|
| Kontainer | `#sidebar` di `stacer/app.ui` (`min-width: 60`) |
| Tombol | **`QPushButton`** (bukan QToolButton), `checkable`, `PointingHandCursor`, `Qt::NoFocus` |
| Daftar tombol | `app.cpp:61` `mListSidebarButtons` = `btnDash, btnStartupApps, btnSystemCleaner, btnSearch, btnServices, btnProcesses, btnUninstaller, btnResources, btnHelpers, btnSettings` (+ `btnAptSourceManager`, `btnGnomeSettings` kondisional) |
| Logika klik/aktif | `app.cpp:186 clickSidebarButton()` + `checkSidebarButtonByTooltip()` — pindah halaman & set `:checked` |
| Style state | `style.qss:387-399` → `#sidebar QPushButton` (default) & `:checked, :hover` (background `@buttonBackground`) |
| Ikon | di-set lewat QSS `qproperty-icon: url(:/static/themes/default/img/sidebar-icons/<x>.png)` (baris 413+) — **PNG bitmap**, perlu diganti SVG sesuai guideline §Icons |
| Drop shadow | `app.cpp:100` `Utilities::addDropShadow(ui->sidebar, 60)` — sudah ada mekanisme elevasi via `QGraphicsDropShadowEffect` |

**Catatan layout:** sidebar saat ini **icon-only** (lebar ~60px), sedangkan mockup ingin
**ikon-di-atas-label** (lebar ~76px). Label/teks tersedia di `.ui` (`text` property ada).
Tidak wajib konversi ke `QToolButton`: `QPushButton` bisa diberi teks + ikon dan ditata via QSS.
Keputusan ditunda ke Fase 4.

---

## 5. Pemisahan logika vs UI

| Modul | Isi |
|---|---|
| `stacer-core/` (lib terpisah) | Logika sistem murni: `Info/` (CPU/RAM/disk/sysinfo), `Tools/`, `Utils/`. Tidak ada kode widget. |
| `stacer/` | Lapisan UI (widget, halaman, manager) — memanggil `stacer-core`. |

Pemisahan **sudah cukup baik**: backend sistem ada di library `stacer-core`, terpisah dari Qt Widgets.
Bagus untuk rencana migrasi QML masa depan, **tapi tidak perlu refactor sekarang**.

---

## 6. Rekomendasi strategi re-style (untuk Fase 2+)

**Pendekatan terbaik: tambah tema baru `pc-manager`, jangan timpa `default`.**

1. Buat folder `stacer/static/themes/pc-manager/style/` berisi `values.ini` + `style.qss`.
2. Isi `values.ini` dengan token PC Manager (lihat `ui-guideline-stacer.md` §2):
   - `@bg=#1c1d27 @sidebar=#191a22 @card=#2a2c39 @accent=#5cc4ef` dst.
   - Petakan ke nama placeholder yang sudah dipakai QSS (`@globalBackground`, `@sidebar`, `@buttonBackground`, ...).
3. Tambah entri ke `stacer/static/themes.json`:
   `{"value":"pc-manager","text":"PC Manager"}`.
4. Daftarkan path baru di `stacer/static.qrc` agar ter-embed.
5. Ganti ikon sidebar PNG → SVG (dari folder `icon/` aset desain) di tema baru.

**Keuntungan:** tema lama utuh → mudah rollback, `git merge upstream/main` minim konflik,
acceptance "tidak ada regresi" terpenuhi.

**QSS gotchas yang terkonfirmasi di kode:** tidak ada `box-shadow` (pakai `addDropShadow` C++ yang
sudah ada), selektor pakai `objectName` (`#sidebar`, `#btnDash`), state `:checked`/`:hover` instan.

---

## 7. Status build (Fase 0) — ✅ SELESAI

- Toolchain: cmake, gcc/g++ 15.2.1 (ccache), ninja, qmake6 — tersedia.
- Qt6 6.10.3: qtbase, qtsvg, qttools (LinguistTools), **qtcharts** (terinstall via `dnf`) — lengkap.
- Konfigurasi: `cmake -B build -G Ninja` → sukses.
- Build: `cmake --build build -j$(nproc)` → **sukses** (83/83), binary di `build/stacer/stacer`.
- Smoke test: `QT_QPA_PLATFORM=offscreen ./build/stacer/stacer` → jalan tanpa crash (UI lama).
- Display nyata tersedia (`DISPLAY=:0` + Wayland) untuk uji GUI manual.

**Acceptance Fase 0 terpenuhi:** aplikasi compile & jalan dengan UI asli (belum diubah).

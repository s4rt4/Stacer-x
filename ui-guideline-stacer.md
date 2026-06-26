# Stacer Reborn — UI Guideline

> Arah desain: **Microsoft PC Manager (Fluent Design, dark theme)**.
> Target framework: **Qt6 Quick / QML** (Qt Quick Controls 2). Acuan pixel: `mockup-stacer.html`.
> Token di sini = `:root` variabel di `mockup-stacer.html`, diport ke QML singleton `Theme.qml`.
> Jaga ketiganya (guideline ↔ mockup ↔ Theme.qml) tetap sinkron.
>
> Catatan: pendekatan QSS lama dibatalkan — lihat `plan-stacer.md` §0. Spesifikasi desain di dokumen
> ini (warna, tipografi, layout, komponen) framework-agnostik dan tetap berlaku; hanya hint implementasi
> Qt yang diubah ke QML.

---

## 1. Prinsip

1. **Card-based.** Konten dikelompokkan dalam kartu rounded di atas background gelap.
2. **Flat & tenang.** Tanpa gradient mencolok, tanpa neon. Satu warna aksen saja (cyan).
3. **Spacing lega.** Whitespace mengerjakan separuh pekerjaan "modern".
4. **Aksen hemat.** Cyan hanya untuk aksi utama, link, dan item nav aktif. Jangan ditebar.
5. **Sentence case** di mana-mana. Bukan Title Case, bukan ALL CAPS.

---

## 2. Color tokens

| Token | Hex | Pemakaian |
|---|---|---|
| `--bg` | `#1c1d27` | Background window utama |
| `--sidebar` | `#191a22` | Background sidebar (sedikit lebih gelap dari bg) |
| `--card` | `#2a2c39` | Background kartu & tile |
| `--card-hover` | `#313342` | Kartu/tile saat hover |
| `--accent` | `#5cc4ef` | Tombol aksi utama (Boost), fill aksen |
| `--accent-text` | `#0c3a50` | Teks di atas `--accent` (navy gelap, bukan hitam) |
| `--accent-soft` | `#6fcdf2` | Link, ikon aktif, teks aksen di atas dark |
| `--text` | `#f0f1f4` | Teks utama |
| `--text-dim` | `#9a9ca8` | Teks sekunder / label / ikon non-aktif |
| `--border` | `rgba(255,255,255,0.06)` | Garis pemisah halus (opsional) |
| `--warn` | `#f0c060` | Ikon aksen sekunder (hero bulb), peringatan ringan |

**Aturan teks di atas warna:** teks pada `--accent` selalu pakai `--accent-text` (navy), **jangan** hitam/abu generik.

---

## 3. Typography

- **Font stack:** `"Segoe UI Variable", "Inter", system-ui, sans-serif`
  (Segoe jika ada di Windows; di Linux fallback ke Inter/system).
- **Hanya dua weight:** 400 (regular) & 500 (medium). Jangan 600/700 — terlalu berat.
- Skala (UI app, kompak):

| Peran | Size | Weight |
|---|---|---|
| Judul kartu | 14px | 500 |
| Body / status | 13px | 400 |
| Label kecil | 11px | 400 |
| Angka metrik | 18px | 500 |
| Nama app (sidebar header) | 13px | 500 |
| Label nav | 11px | 400 |

Tidak ada teks di bawah 11px.

---

## 4. Layout & shape

| Properti | Nilai |
|---|---|
| Radius window | 12px |
| Radius kartu/tile | 10px |
| Radius tombol | 8px |
| Padding kartu | 14–16px |
| Gap antar kartu | 12px |
| Lebar sidebar | ~62px (icon-over-label) |
| Jarak vertikal antar blok konten | 12px |

---

## 5. Komponen

### 5.1 Sidebar nav item
- Layout: **ikon di atas, label di bawah**, rata tengah.
- Default: teks `--text-dim`, background transparan.
- **Aktif**: background `--card`, teks & ikon `--accent-soft`.
- Hover: background `--card-hover`.
- **QML:** `Item`/`Button` custom dengan ikon (di atas) + label (di bawah). State aktif/hover via
  `states` + `Behavior on color` (transisi halus). Warna ikon di-bind ke `Theme` per-state — tidak perlu
  file ikon terpisah per state (ini menyelesaikan keterbatasan QSS `:checked` yang tak bisa swap ikon).

### 5.2 Kartu (card)
- Background `--card`, `border-radius: 10px`, padding 14–16px.
- Tanpa border (atau border `--border` sangat tipis bila perlu).

### 5.3 Tile fitur (grid 2×2)
- Sama seperti kartu. Header: **judul kiri + ikon kecil kanan** (`--text-dim`).
- Isi: label kecil (`--text-dim`) di atas, nilai/status (`--text`) di bawah.
- Beri jarak vertikal antara header dan label (~18px) agar "lega".

### 5.4 Tombol aksen (primary action)
- Background `--accent`, teks `--accent-text`, `border-radius: 8px`, padding ~10px, weight 500, rata tengah.
- Full-width di dalam kartu boost.

### 5.5 Metrik (di kartu boost)
- Strip aksen vertikal kecil (4px, `--accent`, rounded) di kiri tiap metrik.
- Angka 18px/500 + label 11px `--text-dim` di bawahnya.

### 5.6 Hero banner
- Kartu dengan kotak ikon (38px, background `--card-hover`/`#33384a`, ikon bulb `--warn`),
  judul 14px/500, subjudul 12px `--text-dim` dengan link "Learn more ›" `--accent-soft`.

---

## 6. Ikon

- Gunakan **satu set ikon outline/garis yang konsisten** (mis. Tabler, Lucide, atau Material Symbols Outlined). Hindari mencampur beberapa gaya.
- Ukuran: 17–19px di sidebar & header kartu; ikon dekoratif maks 24px.
- Warna: ikut warna teks parent (`--text-dim` default, `--accent-soft` saat aktif).
- **QML:** render SVG via `Image` (mulus di HiDPI) lalu warnai dengan `MultiEffect`/`ColorOverlay`
  (qt5compat `Qt5Compat.GraphicalEffects`) yang di-bind ke `Theme` — satu file SVG, warna mengikuti state.
  Sumber ikon: folder `icon/` (set Lucide outline) di root repo.

Pemetaan ikon nav yang disarankan:

| Halaman | Ikon (konsep) |
|---|---|
| Dashboard | home |
| Cleaner | eraser / broom |
| Services | server |
| Processes | list |
| Startup | play / power |
| Resources | chart line |
| Settings | gear |

---

## 7. Implementasi QML (WAJIB dibaca sebelum styling)

1. **Token terpusat di `Theme.qml` (singleton).** Semua warna/spacing/radius/font dari §2–§4 jadi properti
   `Theme`. Komponen membaca `Theme.bg`, `Theme.card`, `Theme.accent`, dst — jangan hardcode hex di page.
2. **Elevasi/shadow:** pakai `MultiEffect` (`shadowEnabled: true`) atau `DropShadow` (qt5compat). Boleh halus
   atau flat. QML mendukung shadow asli — tak perlu trik C++ lagi.
3. **Animasi:** gunakan `Behavior on <prop> { ColorAnimation/NumberAnimation { duration: 120 } }` dan
   `states`/`transitions`. Hover/aktif harus **bertransisi halus** (bukan seketika seperti QSS).
4. **State warna ikon:** warnai SVG via `MultiEffect`/`ColorOverlay` yang di-bind ke `Theme` per-state —
   satu file ikon, warna ikut state. (Inilah perbaikan atas keterbatasan QSS `:checked` yang tak bisa swap ikon.)
5. **Rounded:** `Rectangle { radius: Theme.radiusCard }`. Untuk clip konten gunakan `layer.enabled` / `clip: true`.
6. **Aksen solid:** tombol aksi pakai warna solid `Theme.accent` (hindari gradient mencolok).
7. **Binding data:** page mengikat ke `Q_PROPERTY`/sinyal controller C++ (lihat `plan-stacer.md` §4).
   Jangan taruh logika sistem di QML.

Contoh kerangka QML (ilustratif):

```qml
// Theme.qml (singleton)
pragma Singleton
import QtQuick
QtObject {
    readonly property color bg:        "#1c1d27"
    readonly property color card:      "#2a2c39"
    readonly property color cardHover: "#313342"
    readonly property color accent:    "#5cc4ef"
    readonly property color accentText:"#0c3a50"
    readonly property color text:      "#f0f1f4"
    readonly property color textDim:   "#9a9ca8"
    readonly property int   radiusCard: 10
    readonly property int   radiusBtn:  8
}

// Card.qml
Rectangle { color: Theme.card; radius: Theme.radiusCard; /* + padding via anchors/margins */ }

// AccentButton.qml
Rectangle {
    radius: Theme.radiusBtn; color: hovered ? Theme.accentSoft : Theme.accent
    Behavior on color { ColorAnimation { duration: 120 } }
    // label: color Theme.accentText, weight Medium
}

// NavItem: state aktif → bg Theme.card, ikon Theme.accentSoft (warna ikon via MultiEffect)
```

---

## 8. Quality floor

- Uji di **KDE Plasma dan GNOME** (Wayland & X11).
- Pastikan tajam di HiDPI (SVG via `Image`, hindari bitmap).
- Tidak ada teks terpotong; kontras teks cukup di atas dark.
- Animasi halus tapi tidak berlebihan (durasi ~100–160ms, easing standar).
- Jangan tambahkan dekorasi yang tidak melayani fungsi.

# UI/UX DESIGN SYSTEM & INTERACTION GUIDELINES

> **Tujuan Dokumen:** Dokumen ini merupakan pangkalan pengetahuan (knowledge base) untuk AI agent dan developer yang mengatur standarisasi antarmuka pengguna (UI), pengalaman pengguna (UX), dan sistem desain (Design System) aplikasi. Patuhi aturan ini agar UI tetap konsisten, responsif, dan memberikan umpan balik yang jelas.

## 1. TEMA & IDENTITAS VISUAL (COLOR & TYPOGRAPHY)
- **Color Palette (Semantic):**
  - `Income` (Pemasukan): Hijau (contoh: `Colors.green.shade700`).
  - `Expense` (Pengeluaran): Merah (contoh: `Colors.red.shade700`).
  - `Transfer`: Biru (contoh: `Colors.blue.shade600`).
  - `Negative Balance`: Merah menyala dengan latar belakang transparan merah (Red Tint) pada kartu Kantong (Wallet) sebagai peringatan agresif tanpa memblokir interaksi.
  - `Background`: Abu-abu sangat terang (contoh: `Colors.grey.shade50`) untuk menonjolkan elevasi komponen Card.
- **Typography:** Gunakan `TextTheme` bawaan Material 3. Hindari custom fonts yang berat.
  - `headlineSmall`/`titleLarge`: Untuk total saldo dan angka utama (Gunakan font weight tebal/bold).
  - `bodyMedium`: Untuk deskripsi transaksi.
  - `labelSmall`: Untuk tanggal dan metadata.
  - Format angka wajib menggunakan pemisah ribuan (contoh: Rp 1.500.000).

## 2. SISTEM TATA LETAK & SPASI (LAYOUT & SPACING)
- **Aturan Kelipatan 8 (8pt Grid System):** Semua padding, margin, dan jarak antar elemen harus menggunakan kelipatan 8 (8, 16, 24, 32).
  - Padding standar batas layar: 16px.
  - Jarak antar Card vertikal: 8px atau 12px.
- **Border Radius:** Gunakan sudut melengkung yang konsisten. Standar radius untuk Card dan BottomSheet adalah 16px. Untuk Button adalah 8px atau 12px (Standar Material 3).

## 3. PANDUAN KOMPONEN (COMPONENT GUIDELINES)
- **Input Transaksi (Form):**
  - Gunakan `ModalBottomSheet` yang bisa digeser (scrollable) dari bawah untuk input transaksi baru, alih-alih berpindah ke halaman (`Route`) baru. Ini mempertahankan konteks layar pengguna dan ramah untuk penggunaan satu tangan.
  - Input nominal wajib menggunakan *auto-formatting* ribuan secara *real-time* saat pengguna mengetik.
- **Kartu Transaksi (Transaction Card):**
  - Komponen wajib memuat: Ikon Kategori, Nama Kategori, Tanggal, dan Nominal.
  - Nominal harus menggunakan warna semantik (Hijau/Merah/Biru).
- **Indikator "Tutup Buku" (Locked Period):**
  - Transaksi yang berada pada periode terkunci harus memiliki ikon "Gembok" (Lock) kecil di sudut kartu.
  - Jika pengguna menggeser (swipe) atau menekan transaksi terkunci untuk menghapus/mengedit, sistem harus menolak aksi tersebut dan menampilkan `SnackBar` peringatan.
- **Kategori & Kantong Tidak Aktif (Soft Deleted):**
  - Entitas dengan `isActive == false` tidak boleh muncul di pilihan dropdown form input.
  - Di halaman Riwayat, entitas tersebut tetap dirender namun berikan penanda visual (misal: warna teks sedikit diredam/abu-abu atau ikon dicoret) agar pengguna tahu itu adalah entitas masa lalu.

## 4. PENANGANAN STATE & UMPAN BALIK (STATE & FEEDBACK UX)
- **Empty States (Keadaan Kosong):**
  - JANGAN PERNAH menampilkan layar kosong tanpa instruksi. Selalu gunakan teks ajakan bertindak (Call to Action). Contoh: "Belum ada pengeluaran bulan ini. Ketuk tombol + untuk mencatat."
- **Loading States:**
  - Patuhi aturan `skipLoadingOnReload: true` pada `AsyncValue` Riverpod.
  - DILARANG menggunakan *full-screen loading spinner* saat memuat ulang (refresh) data setelah menambah/menghapus transaksi. Gunakan transisi grafis yang mulus.
  - Saat tombol "Simpan" ditekan, ubah teks tombol menjadi indikator *loading* melingkar (*CircularProgressIndicator* kecil) di dalam tombol untuk mencegah *double-submit*.
- **Error States:**
  - Tangkap exception logika bisnis dari Repository dan tampilkan menggunakan `ScaffoldMessenger.showSnackBar()`. Pesan harus jelas, ringkas, dan berbahasa Indonesia.

## 5. NAVIGASI (ROUTING)
- Gunakan paket `GoRouter` untuk manajemen rute.
- **Main Layout:** Gunakan `NavigationBar` (Material 3 Bottom Navigation) dengan 4 tab utama:
  1. **Dashboard:** Ringkasan dompet dan agregasi singkat periode berjalan.
  2. **Transaksi:** Daftar riwayat kronologis lengkap dengan fungsi filter (Bulan/Jenis/Kantong).
  3. **Laporan:** Rendering agregasi Chart (menggunakan *Isolate*).
  4. **Pengaturan:** Manajemen entitas (Kantong, Kategori), Tutup Buku, dan (kelak) Sinkronisasi.
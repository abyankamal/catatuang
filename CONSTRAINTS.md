# Constraints & Standards: CatatUang

Dokumen ini mendefinisikan standar mutu teknis, kepatuhan platform Android/iOS, serta batas kualitas kode (*quality gates*) yang wajib dipatuhi sebelum rilis ke produksi (Google Play Store & App Store).

---

## 1. Floor Constraints (Wajib Selalu Terpenuhi)

- **Android 16 KB Page Size Alignment**:
  - Seluruh file pustaka biner (*native shared libraries* `.so`) yang dibundel di dalam APK/AAB arsitektur 64-bit (`arm64-v8a` dan `x86_64`) wajib dikompilasi dengan ELF segment alignment $\ge 16.384$ bytes (16 KB / 64 KB).
  - Pustaka native tidak boleh memakai alignment warisan 4.096 bytes (4 KB) untuk mematuhi mandat wajib Google Play Store bagi perangkat Android 15+.
  - Konfigurasi `packaging.jniLibs.useLegacyPackaging = false` dipertahankan di `android/app/build.gradle.kts` agar library ter-align dan di-page-map langsung tanpa uncompressed zip distortion.
- **Integritas Transaksi Finansial (ACID & Reversal)**:
  - Setiap mutasi dompet/transaksi wajib dalam single `isar.writeTxn()`.
  - Transaksi transfer (`TRANSFER_IN`, `TRANSFER_OUT`, `EXPENSE`) dan transaksi utang (`debtSyncId`) terkunci dari edit parsial sepihak untuk mencegah desinkronisasi nominal.
- **Off-Main-Thread Concurrency**:
  - Seluruh agregasi finansial skala besar (budget summary, pencarian riwayat, pengingat jatuh tempo) wajib dieksekusi di `Isolate.run()`.

---

## 2. Enforced with Numbers & Quality Gates

| Dimensi | Batasan / Target | Cara Pengecekan | Kapan Berjalan |
| :--- | :--- | :--- | :--- |
| **Android 16 KB Alignment** | ELF Load Align $\ge 16384$ | Inspeksi ELF header `.so` di APK | Setiap build rilis (`assembleRelease` / `bundleRelease`) |
| **Static Analysis** | 0 error, 0 warning | `flutter analyze` | Setiap commit & PR |
| **Automated Tests** | 100% pass (51/51 test) | `flutter test` | Setiap commit & PR |
| **Target SDK Android** | Min API 21, Target API 35+ | `android/app/build.gradle.kts` | Pre-submission |

---

## 3. Hasil Audit Kepatuhan 16 KB Terkini (Status: FULLY COMPLIANT ✅)

Hasil inspeksi aktual terhadap seluruh pustaka biner `.so` pada APK Release (`build/app/outputs/flutter-apk/app-release.apk`):

```text
lib/arm64-v8a/libapp.so      -> [65536, 65536, 65536] (64 KB)     -> COMPLIANT ✅
lib/arm64-v8a/libdartjni.so  -> [16384, 16384, 16384] (16 KB)     -> COMPLIANT ✅
lib/arm64-v8a/libflutter.so  -> [65536, 65536, 65536] (64 KB)     -> COMPLIANT ✅
lib/arm64-v8a/libisar.so     -> [16384, 16384, 16384, 16384] (16 KB) -> COMPLIANT ✅
lib/x86_64/libapp.so         -> [65536, 65536, 65536] (64 KB)     -> COMPLIANT ✅
lib/x86_64/libdartjni.so     -> [16384, 16384, 16384] (16 KB)     -> COMPLIANT ✅
lib/x86_64/libflutter.so     -> [65536, 65536, 65536] (64 KB)     -> COMPLIANT ✅
lib/x86_64/libisar.so        -> [16384, 16384, 16384, 16384] (16 KB) -> COMPLIANT ✅
```

**Kesimpulan:** 100% pustaka native di dalam aplikasi kini memenuhi standar **Android 16 KB Page Size**. Aplikasi berjalan mulus di Android 15+ / API 37 tanpa peringatan kompatibilitas dan siap untuk Google Play Store.

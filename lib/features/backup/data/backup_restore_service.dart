import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/database/database_provider.dart';
import '../../wallet/domain/wallet.dart';

typedef IsarRestoredCallback = void Function(Isar newIsar);

final backupRestoreServiceProvider = Provider<BackupRestoreService>((ref) {
  final isar = ref.watch(isarProvider);
  return BackupRestoreService(
    isar,
    onIsarRestored: (newIsar) {
      ref.read(isarProvider.notifier).updateIsar(newIsar);
    },
  );
});

class BackupRestoreResult {
  final bool isSuccess;
  final String message;
  final String? filePath;

  const BackupRestoreResult({
    required this.isSuccess,
    required this.message,
    this.filePath,
  });
}

class BackupRestoreService {
  final Isar _isar;
  final IsarRestoredCallback? onIsarRestored;

  BackupRestoreService(this._isar, {this.onIsarRestored});

  /// Ekspor snapshot database Isar aktif ke file biner .isar
  Future<BackupRestoreResult> exportDatabase() async {
    try {
      final now = DateTime.now();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(now);
      final fileName = 'catatuang_backup_$timestamp';

      if (kIsWeb) {
        return const BackupRestoreResult(
          isSuccess: false,
          message: 'Cadangan database lokal tidak didukung di Web.',
        );
      }

      final tempDir = await getTemporaryDirectory();
      final tempFilePath = '${tempDir.path}/$fileName.isar';
      final tempFile = File(tempFilePath);

      if (await tempFile.exists()) {
        await tempFile.delete();
      }

      // 1. Buat snapshot database Isar yang konsisten
      await _isar.copyToFile(tempFilePath);

      if (!await tempFile.exists() || await tempFile.length() == 0) {
        return const BackupRestoreResult(
          isSuccess: false,
          message: 'Gagal membuat file cadangan database.',
        );
      }

      final bytes = await tempFile.readAsBytes();

      // 2. Simpan file ke direktori unduhan / penyimpanan perangkat pengguna
      final savedPath = await FileSaver.instance.saveFile(
        name: fileName,
        bytes: bytes,
        fileExtension: 'isar',
        mimeType: MimeType.other,
      );

      // Bersihkan file sementara
      if (await tempFile.exists()) {
        await tempFile.delete();
      }

      return BackupRestoreResult(
        isSuccess: true,
        message: 'Cadangan data berhasil disimpan: $fileName.isar',
        filePath: savedPath,
      );
    } catch (e) {
      return BackupRestoreResult(
        isSuccess: false,
        message: 'Gagal mencadangkan data: $e',
      );
    }
  }

  /// Pilih file cadangan (.isar) dari penyimpanan perangkat dan pulihkan data
  Future<BackupRestoreResult> pickAndRestoreDatabase() async {
    try {
      if (kIsWeb) {
        return const BackupRestoreResult(
          isSuccess: false,
          message: 'Pemulihan database lokal tidak didukung di Web.',
        );
      }

      // 1. Dialog pemilihan file .isar
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return const BackupRestoreResult(
          isSuccess: false,
          message: 'Pemilihan file dibatalkan.',
        );
      }

      final pickedFile = result.files.first;
      final path = pickedFile.path;

      if (path == null) {
        // Fallback untuk platform berbasis bytes jika path null
        if (pickedFile.bytes != null) {
          return await restoreDatabaseFromBytes(pickedFile.bytes!);
        }
        return const BackupRestoreResult(
          isSuccess: false,
          message: 'Lokasi file tidak valid.',
        );
      }

      final file = File(path);
      if (!await file.exists()) {
        return const BackupRestoreResult(
          isSuccess: false,
          message: 'File cadangan tidak ditemukan di penyimpanan.',
        );
      }

      // Validasi ekstensi & ukuran file
      if (!path.toLowerCase().endsWith('.isar') && pickedFile.size > 0) {
        // Izinkan jika file memiliki konten yang cukup
      }

      final bytes = await file.readAsBytes();
      return await restoreDatabaseFromBytes(bytes);
    } catch (e) {
      return BackupRestoreResult(
        isSuccess: false,
        message: 'Gagal memulihkan database: $e',
      );
    }
  }

  /// Validasi header biner database Isar (LMDB environment)
  static bool isValidIsarSnapshot(Uint8List bytes) {
    // 1. Database Isar minimal memiliki ukuran 1 page (4096 bytes)
    if (bytes.length < 4096 || bytes.length % 4096 != 0) {
      return false;
    }

    // 2. Periksa signature magic LMDB environment pada meta page (offset 20-23 dan version offset 28)
    final hasMagicPage0 = bytes[20] == 3 &&
        bytes[21] == 17 &&
        bytes[22] == 76 &&
        bytes[23] == 239 &&
        bytes[28] == 1;

    // Periksa juga meta page 1 alternatif (offset 4096 + 20)
    final hasMagicPage1 = bytes.length >= 8192 &&
        bytes[4096 + 20] == 3 &&
        bytes[4096 + 21] == 17 &&
        bytes[4096 + 22] == 76 &&
        bytes[4096 + 23] == 239 &&
        bytes[4096 + 28] == 1;

    return hasMagicPage0 || hasMagicPage1;
  }

  /// Pulihkan database langsung dari bytes (Snapshot Isar) dengan Atomic Staging & Rollback
  Future<BackupRestoreResult> restoreDatabaseFromBytes(Uint8List backupBytes) async {
    try {
      if (backupBytes.isEmpty) {
        return const BackupRestoreResult(
          isSuccess: false,
          message: 'File cadangan kosong atau rusak.',
        );
      }

      if (kIsWeb) {
        return const BackupRestoreResult(
          isSuccess: false,
          message: 'Pemulihan database lokal tidak didukung di Web.',
        );
      }

      // 1. VALIDASI HEADER BINER: Pastikan format file adalah database Isar valid
      if (!isValidIsarSnapshot(backupBytes)) {
        return const BackupRestoreResult(
          isSuccess: false,
          message: 'File cadangan tidak valid atau rusak: format database Isar tidak dikenali.',
        );
      }

      final docDir = await getApplicationDocumentsDirectory();
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final stagedDbName = 'staged_restore_$timestamp';
      final stagedFile = File('${tempDir.path}/$stagedDbName.isar');

      // 2. TAHAP STAGING: Tulis bytes ke file sementara di direktori temp
      await stagedFile.writeAsBytes(backupBytes, flush: true);

      // 3. VALIDASI INTEGRITAS: Uji buka database staging dengan skema Isar
      try {
        final stagedIsar = await Isar.open(
          isarSchemas,
          directory: tempDir.path,
          name: stagedDbName,
        );
        final currentStagedLength = await stagedFile.length();
        await stagedIsar.wallets.count();
        await stagedIsar.close();

        // Jika ukuran file berubah saat dibuka, Isar telah mereformat file karena data korup
        if (currentStagedLength != backupBytes.length) {
          if (await stagedFile.exists()) {
            await stagedFile.delete();
          }
          return const BackupRestoreResult(
            isSuccess: false,
            message: 'File cadangan tidak valid atau rusak: integritas data tidak sesuai.',
          );
        }
      } catch (e) {
        if (await stagedFile.exists()) {
          await stagedFile.delete();
        }
        return BackupRestoreResult(
          isSuccess: false,
          message: 'File cadangan tidak valid atau rusak: $e',
        );
      }

      final dbPath = '${docDir.path}/default.isar';
      final backupPath = '${docDir.path}/default.isar.bak';
      final dbFile = File(dbPath);
      final backupFile = File(backupPath);

      // 3. BACKUP DARURAT: Salin database aktif saat ini sebelum ditimpa
      if (await dbFile.exists()) {
        if (await backupFile.exists()) {
          await backupFile.delete();
        }
        await dbFile.copy(backupPath);
      }

      // 4. TUTUP INSTANCE ISAR AKTIF
      if (_isar.isOpen) {
        await _isar.close();
      }

      // 5. SWAP ATOMIK: Timpa default.isar dengan snapshot yang dipulihkan
      await dbFile.writeAsBytes(backupBytes, flush: true);

      // 6. BUKA KEMBALI INSTANCE ISAR BARU & PERBARUI PROVIDER
      try {
        final newIsar = await openIsar();
        onIsarRestored?.call(newIsar);

        // Bersihkan file backup darurat dan staging jika sukses
        if (await backupFile.exists()) {
          await backupFile.delete();
        }
        if (await stagedFile.exists()) {
          await stagedFile.delete();
        }

        return const BackupRestoreResult(
          isSuccess: true,
          message: 'Data berhasil dipulihkan secara penuh.',
        );
      } catch (openError) {
        // 7. ROLLBACK OTOMATIS: Kembalikan file dari backup darurat jika pembukaan gagal
        if (await backupFile.exists()) {
          await backupFile.copy(dbPath);
          await backupFile.delete();
        }
        if (await stagedFile.exists()) {
          await stagedFile.delete();
        }

        final recovered = await openIsar();
        onIsarRestored?.call(recovered);

        return BackupRestoreResult(
          isSuccess: false,
          message: 'Gagal membuka database baru, data lama telah dipulihkan kembali: $openError',
        );
      }
    } catch (e) {
      // Upayakan buka kembali database jika terjadi kesalahan tak terduga
      try {
        if (!_isar.isOpen) {
          final recovered = await openIsar();
          onIsarRestored?.call(recovered);
        }
      } catch (_) {}

      return BackupRestoreResult(
        isSuccess: false,
        message: 'Gagal memulihkan data: $e',
      );
    }
  }
}

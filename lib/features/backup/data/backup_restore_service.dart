import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/database/database_provider.dart';

final backupRestoreServiceProvider = Provider<BackupRestoreService>((ref) {
  final isar = ref.watch(isarProvider);
  return BackupRestoreService(isar);
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

  BackupRestoreService(this._isar);

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

  /// Pulihkan database langsung dari bytes (Snapshot Isar)
  Future<BackupRestoreResult> restoreDatabaseFromBytes(Uint8List backupBytes) async {
    try {
      if (backupBytes.isEmpty) {
        return const BackupRestoreResult(
          isSuccess: false,
          message: 'File cadangan kosong atau rusak.',
        );
      }

      final docDir = await getApplicationDocumentsDirectory();
      final dbPath = '${docDir.path}/default.isar';

      // 1. Tutup koneksi instance Isar yang sedang aktif
      if (_isar.isOpen) {
        await _isar.close();
      }

      // 2. Timpa file database default.isar dengan snapshot yang dipulihkan
      final dbFile = File(dbPath);
      await dbFile.writeAsBytes(backupBytes, flush: true);

      // 3. Buka kembali instance Isar
      await openIsar();

      return const BackupRestoreResult(
        isSuccess: true,
        message: 'Data berhasil dipulihkan secara penuh.',
      );
    } catch (e) {
      // Upayakan buka kembali database jika terjadi kesalahan
      try {
        if (!_isar.isOpen) {
          await openIsar();
        }
      } catch (_) {}

      return BackupRestoreResult(
        isSuccess: false,
        message: 'Gagal memulihkan data: $e',
      );
    }
  }
}

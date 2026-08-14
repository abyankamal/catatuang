import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/database_provider.dart';
import '../domain/app_settings.dart';

final appSettingsRepositoryProvider = Provider<AppSettingsRepository>((ref) {
  final isar = ref.watch(isarProvider);
  return AppSettingsRepository(isar);
});

class AppSettingsRepository {
  final Isar _isar;
  final _uuid = const Uuid();

  AppSettingsRepository(this._isar);

  Stream<AppSettings?> watchSettings() {
    return _isar.appSettings.where().watch(fireImmediately: true).map((list) {
      return list.isNotEmpty ? list.first : null;
    });
  }

  Future<AppSettings> getOrInitSettings() async {
    final existing = await _isar.appSettings.where().findFirst();
    if (existing != null) {
      return existing;
    }

    // Init singleton settings
    late AppSettings created;
    await _isar.writeTxn(() async {
      final now = DateTime.now();
      created = AppSettings()
        ..syncId = _uuid.v4()
        ..lockedUntil = null
        ..createdAt = now
        ..updatedAt = now;
      await _isar.appSettings.put(created);
    });

    return created;
  }

  Future<void> updateProfile({
    required String userName,
    String? avatarIcon,
  }) async {
    final settings = await getOrInitSettings();
    settings.userName = userName;
    settings.avatarIcon = avatarIcon;
    settings.updatedAt = DateTime.now();

    await _isar.writeTxn(() async {
      await _isar.appSettings.put(settings);
    });
  }

  /// Menandai onboarding selesai dan menyimpan profil pengguna
  Future<void> completeOnboarding({
    required String userName,
    String? avatarIcon,
  }) async {
    final settings = await getOrInitSettings();
    settings.userName = userName;
    settings.avatarIcon = avatarIcon;
    settings.hasCompletedOnboarding = true;
    settings.updatedAt = DateTime.now();

    await _isar.writeTxn(() async {
      await _isar.appSettings.put(settings);
    });
  }

  /// Memperbarui tanggal batas periode terkunci (Tutup Buku)
  Future<void> updateLockedUntil(DateTime? lockedUntil) async {
    final settings = await getOrInitSettings();
    
    // Normalisasi ke akhir hari (23:59:59.999) jika tanggal diberikan
    final normalized = lockedUntil != null
        ? DateTime(
            lockedUntil.year,
            lockedUntil.month,
            lockedUntil.day,
            23,
            59,
            59,
            999,
          )
        : null;

    settings.lockedUntil = normalized;
    settings.updatedAt = DateTime.now();

    await _isar.writeTxn(() async {
      await _isar.appSettings.put(settings);
    });
  }

  /// Memperbarui preferensi privasi blur layar saat app switcher
  Future<void> updatePrivacyScreen(bool isEnabled) async {
    final settings = await getOrInitSettings();
    settings.isPrivacyScreenEnabled = isEnabled;
    settings.updatedAt = DateTime.now();

    await _isar.writeTxn(() async {
      await _isar.appSettings.put(settings);
    });
  }

  /// Reset/hapus seluruh isi database Isar secara instan
  Future<void> clearAllData() async {
    await _isar.writeTxn(() async {
      await _isar.clear();
    });
  }
}

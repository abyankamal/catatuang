import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/utils/pin_security_helper.dart';
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

  /// Memperbarui preferensi pengingat notifikasi utang & piutang
  Future<void> updateDebtReminder(bool isEnabled) async {
    final settings = await getOrInitSettings();
    settings.isDebtReminderEnabled = isEnabled;
    settings.updatedAt = DateTime.now();

    await _isar.writeTxn(() async {
      await _isar.appSettings.put(settings);
    });
  }

  /// Setel PIN baru 6-digit dengan salt dan hash SHA-256
  Future<void> setPin(String pin) async {
    if (pin.length != 6 || int.tryParse(pin) == null) {
      throw ArgumentError('PIN harus terdiri dari 6 digit angka.');
    }

    final salt = PinSecurityHelper.generateSalt();
    final hash = PinSecurityHelper.hashPin(pin, salt);

    final settings = await getOrInitSettings();
    settings.isPinEnabled = true;
    settings.pinSalt = salt;
    settings.pinHash = hash;
    settings.updatedAt = DateTime.now();

    await _isar.writeTxn(() async {
      await _isar.appSettings.put(settings);
    });
  }

  /// Nonaktifkan penguncian PIN
  Future<void> disablePin() async {
    final settings = await getOrInitSettings();
    settings.isPinEnabled = false;
    settings.pinHash = null;
    settings.pinSalt = null;
    settings.updatedAt = DateTime.now();

    await _isar.writeTxn(() async {
      await _isar.appSettings.put(settings);
    });
  }

  /// Verifikasi PIN yang dimasukkan
  Future<bool> verifyPin(String enteredPin) async {
    final settings = await getOrInitSettings();
    if (!settings.isPinEnabled || settings.pinHash == null || settings.pinSalt == null) {
      return true; // Jika PIN tidak aktif, anggap valid
    }

    return PinSecurityHelper.verifyPin(
      enteredPin: enteredPin,
      storedHash: settings.pinHash!,
      storedSalt: settings.pinSalt!,
    );
  }

  /// Reset/hapus seluruh isi database Isar secara instan
  Future<void> clearAllData() async {
    await _isar.writeTxn(() async {
      await _isar.clear();
    });
  }
}

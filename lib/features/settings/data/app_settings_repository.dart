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
}

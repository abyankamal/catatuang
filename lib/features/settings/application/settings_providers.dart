import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/app_settings_repository.dart';
import '../domain/app_settings.dart';

final appSettingsStreamProvider = StreamProvider<AppSettings?>((ref) {
  final repo = ref.watch(appSettingsRepositoryProvider);
  return repo.watchSettings();
});

final settingsControllerProvider = StateNotifierProvider<SettingsController, AsyncValue<void>>((ref) {
  final repo = ref.watch(appSettingsRepositoryProvider);
  return SettingsController(repo, ref);
});

class SettingsController extends StateNotifier<AsyncValue<void>> {
  final AppSettingsRepository _repo;
  final Ref _ref;

  SettingsController(this._repo, this._ref) : super(const AsyncValue.data(null));

  Future<bool> updateProfile({
    required String userName,
    String? avatarIcon,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repo.updateProfile(
        userName: userName,
        avatarIcon: avatarIcon,
      );
      _ref.invalidate(appSettingsStreamProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> setLockedUntil(DateTime date) async {
    state = const AsyncValue.loading();
    try {
      await _repo.updateLockedUntil(date);
      _ref.invalidate(appSettingsStreamProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> unlockPeriod() async {
    state = const AsyncValue.loading();
    try {
      await _repo.updateLockedUntil(null);
      _ref.invalidate(appSettingsStreamProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> setPrivacyScreenEnabled(bool isEnabled) async {
    state = const AsyncValue.loading();
    try {
      await _repo.updatePrivacyScreen(isEnabled);
      _ref.invalidate(appSettingsStreamProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> setDebtReminderEnabled(bool isEnabled) async {
    state = const AsyncValue.loading();
    try {
      await _repo.updateDebtReminder(isEnabled);
      _ref.invalidate(appSettingsStreamProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> clearAllData() async {
    state = const AsyncValue.loading();
    try {
      await _repo.clearAllData();
      _ref.invalidate(appSettingsStreamProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

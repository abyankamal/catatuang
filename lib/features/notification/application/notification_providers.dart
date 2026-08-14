import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../debt/application/debt_providers.dart';
import '../../settings/application/settings_providers.dart';
import '../data/notification_repository.dart';
import '../domain/app_notification.dart';

final activeRemindersProvider = FutureProvider.autoDispose<List<AppNotificationItem>>((ref) async {
  final settings = ref.watch(appSettingsStreamProvider).valueOrNull;
  final isEnabled = settings?.isDebtReminderEnabled ?? true;

  if (!isEnabled) return const [];

  // Watch debts stream to automatically refresh reminders when debt collection changes
  ref.watch(activeDebtsStreamProvider);

  final repo = ref.watch(notificationRepositoryProvider);
  return await repo.getActiveDebtReminders();
});

final unreadRemindersCountProvider = Provider.autoDispose<int>((ref) {
  final remindersAsync = ref.watch(activeRemindersProvider);
  return remindersAsync.valueOrNull?.length ?? 0;
});

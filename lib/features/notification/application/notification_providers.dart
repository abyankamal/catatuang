import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../debt/application/debt_providers.dart';
import '../../settings/application/settings_providers.dart';
import '../../transaction/application/recurring_transaction_controller.dart';
import '../data/notification_repository.dart';
import '../domain/app_notification.dart';

final activeRemindersProvider = FutureProvider.autoDispose<List<AppNotificationItem>>((ref) async {
  final settings = ref.watch(appSettingsStreamProvider).valueOrNull;
  final isDebtEnabled = settings?.isDebtReminderEnabled ?? true;

  // Watch streams to automatically refresh reminders when collections change
  ref.watch(activeDebtsStreamProvider);
  ref.watch(activeRecurringStreamProvider);

  final repo = ref.watch(notificationRepositoryProvider);
  return await repo.getActiveReminders(
    includeDebt: isDebtEnabled,
    includeRecurring: true,
  );
});

final unreadRemindersCountProvider = Provider.autoDispose<int>((ref) {
  final remindersAsync = ref.watch(activeRemindersProvider);
  return remindersAsync.valueOrNull?.length ?? 0;
});

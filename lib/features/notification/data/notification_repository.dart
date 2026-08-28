import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../../../core/database/database_provider.dart';
import '../../contact/domain/contact.dart';
import '../../debt/domain/debt.dart';
import '../domain/app_notification.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final isar = ref.watch(isarProvider);
  return NotificationRepository(isar);
});

class NotificationRepository {
  final Isar _isar;

  NotificationRepository(this._isar);

  /// Mengambil daftar utang & piutang yang membutuhkan pengingat (due soon, due today, overdue)
  Future<List<AppNotificationItem>> getActiveDebtReminders() async {
    final activeDebts = await _isar.debts
        .filter()
        .isActiveEqualTo(true)
        .and()
        .dueDateIsNotNull()
        .findAll();

    if (activeDebts.isEmpty) return const [];

    final unpaidDebts = activeDebts.where((d) => d.paidAmount < d.totalAmount).toList();
    if (unpaidDebts.isEmpty) return const [];

    final contacts = await _isar.contacts.where().findAll();
    final contactMap = {for (final c in contacts) c.syncId: c};
    final debtMap = {for (final d in unpaidDebts) d.id: d};

    // 1. Direct computation on main thread for smaller datasets
    if (kIsWeb || unpaidDebts.length < 50) {
      return _computeRemindersDirect(unpaidDebts, contactMap);
    }

    // 2. Lightweight zero-allocation isolate delegation for larger datasets
    final payload = _ReminderIsolatePayload(
      debts: [
        for (final d in unpaidDebts)
          _DebtReminderDto(
            id: d.id,
            title: d.title,
            type: d.type,
            totalAmount: d.totalAmount,
            paidAmount: d.paidAmount,
            dueDateIso: d.dueDate!.toIso8601String(),
            contactSyncId: d.contactSyncId,
          ),
      ],
      contactNames: {for (final c in contacts) c.syncId: c.name},
    );

    final reminderResults = await Isolate.run(() => _computeRemindersInIsolate(payload));

    final results = <AppNotificationItem>[];
    for (final r in reminderResults) {
      final debt = debtMap[r.debtId];
      if (debt == null) continue;
      final contact = contactMap[debt.contactSyncId];

      results.add(
        AppNotificationItem(
          id: r.id,
          title: r.title,
          message: r.message,
          type: r.type,
          urgency: r.urgency,
          debtId: r.debtId,
          debt: debt,
          contact: contact,
          dueDate: debt.dueDate!,
          remainingAmount: r.remainingAmount,
        ),
      );
    }

    return results;
  }

  static List<AppNotificationItem> _computeRemindersDirect(
    List<Debt> unpaidDebts,
    Map<String, Contact> contactMap,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final results = <AppNotificationItem>[];

    for (final debt in unpaidDebts) {
      final dueDate = debt.dueDate!;
      final dueDay = DateTime(dueDate.year, dueDate.month, dueDate.day);
      final remaining = debt.totalAmount - debt.paidAmount;
      final contact = contactMap[debt.contactSyncId];
      final contactName = contact?.name ?? 'Pihak Terkait';
      final isPayable = debt.type == 'PAYABLE';
      final diffDays = dueDay.difference(today).inDays;

      NotificationUrgency? urgency;
      String notifTitle = '';
      String notifMessage = '';

      if (diffDays < 0) {
        // Terlewat / Overdue
        urgency = NotificationUrgency.overdue;
        final overdueDays = diffDays.abs();
        notifTitle = isPayable ? 'Utang Terlewat Jatuh Tempo' : 'Piutang Belum Tertagih';
        notifMessage = isPayable
            ? 'Utang "${debt.title}" ke $contactName sudah lewat $overdueDays hari.'
            : 'Tagihan "${debt.title}" ke $contactName sudah lewat $overdueDays hari.';
      } else if (diffDays == 0) {
        // Jatuh tempo hari ini
        urgency = NotificationUrgency.dueToday;
        notifTitle = isPayable ? 'Utang Jatuh Tempo Hari Ini' : 'Piutang Jatuh Tempo Hari Ini';
        notifMessage = isPayable
            ? 'Segera lunasi utang "${debt.title}" ke $contactName hari ini.'
            : 'Hari ini jadwal penagihan "${debt.title}" ke $contactName.';
      } else if (diffDays <= 3) {
        // Mendekati jatuh tempo (1 - 3 hari lagi)
        urgency = NotificationUrgency.upcoming;
        notifTitle = isPayable ? 'Pengingat Utang ($diffDays hari lagi)' : 'Pengingat Piutang ($diffDays hari lagi)';
        notifMessage = isPayable
            ? 'Utang "${debt.title}" ke $contactName jatuh tempo dalam $diffDays hari.'
            : 'Pinjaman "${debt.title}" ke $contactName jatuh tempo dalam $diffDays hari.';
      }

      if (urgency != null) {
        results.add(
          AppNotificationItem(
            id: 'debt_reminder_${debt.id}',
            title: notifTitle,
            message: notifMessage,
            type: debt.type,
            urgency: urgency,
            debtId: debt.id,
            debt: debt,
            contact: contact,
            dueDate: dueDate,
            remainingAmount: remaining,
          ),
        );
      }
    }

    // Urutkan: Overdue -> Due Today -> Upcoming
    results.sort((a, b) {
      final urgencyOrder = {
        NotificationUrgency.overdue: 0,
        NotificationUrgency.dueToday: 1,
        NotificationUrgency.upcoming: 2,
      };
      final orderDiff = urgencyOrder[a.urgency]!.compareTo(urgencyOrder[b.urgency]!);
      if (orderDiff != 0) return orderDiff;
      return a.dueDate.compareTo(b.dueDate);
    });

    return results;
  }

  static List<_ReminderCalculatedDto> _computeRemindersInIsolate(_ReminderIsolatePayload payload) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final results = <_ReminderCalculatedDto>[];

    for (final d in payload.debts) {
      final dueDate = DateTime.parse(d.dueDateIso);
      final dueDay = DateTime(dueDate.year, dueDate.month, dueDate.day);
      final remaining = d.totalAmount - d.paidAmount;
      final contactName = payload.contactNames[d.contactSyncId] ?? 'Pihak Terkait';
      final isPayable = d.type == 'PAYABLE';
      final diffDays = dueDay.difference(today).inDays;

      NotificationUrgency? urgency;
      String notifTitle = '';
      String notifMessage = '';

      if (diffDays < 0) {
        urgency = NotificationUrgency.overdue;
        final overdueDays = diffDays.abs();
        notifTitle = isPayable ? 'Utang Terlewat Jatuh Tempo' : 'Piutang Belum Tertagih';
        notifMessage = isPayable
            ? 'Utang "${d.title}" ke $contactName sudah lewat $overdueDays hari.'
            : 'Tagihan "${d.title}" ke $contactName sudah lewat $overdueDays hari.';
      } else if (diffDays == 0) {
        urgency = NotificationUrgency.dueToday;
        notifTitle = isPayable ? 'Utang Jatuh Tempo Hari Ini' : 'Piutang Jatuh Tempo Hari Ini';
        notifMessage = isPayable
            ? 'Segera lunasi utang "${d.title}" ke $contactName hari ini.'
            : 'Hari ini jadwal penagihan "${d.title}" ke $contactName.';
      } else if (diffDays <= 3) {
        urgency = NotificationUrgency.upcoming;
        notifTitle = isPayable ? 'Pengingat Utang ($diffDays hari lagi)' : 'Pengingat Piutang ($diffDays hari lagi)';
        notifMessage = isPayable
            ? 'Utang "${d.title}" ke $contactName jatuh tempo dalam $diffDays hari.'
            : 'Pinjaman "${d.title}" ke $contactName jatuh tempo dalam $diffDays hari.';
      }

      if (urgency != null) {
        results.add(
          _ReminderCalculatedDto(
            id: 'debt_reminder_${d.id}',
            debtId: d.id,
            title: notifTitle,
            message: notifMessage,
            type: d.type,
            urgency: urgency,
            dueDateIso: d.dueDateIso,
            remainingAmount: remaining,
          ),
        );
      }
    }

    results.sort((a, b) {
      final urgencyOrder = {
        NotificationUrgency.overdue: 0,
        NotificationUrgency.dueToday: 1,
        NotificationUrgency.upcoming: 2,
      };
      final orderDiff = urgencyOrder[a.urgency]!.compareTo(urgencyOrder[b.urgency]!);
      if (orderDiff != 0) return orderDiff;
      return a.dueDateIso.compareTo(b.dueDateIso);
    });

    return results;
  }
}

class _DebtReminderDto {
  final int id;
  final String title;
  final String type;
  final double totalAmount;
  final double paidAmount;
  final String dueDateIso;
  final String contactSyncId;

  const _DebtReminderDto({
    required this.id,
    required this.title,
    required this.type,
    required this.totalAmount,
    required this.paidAmount,
    required this.dueDateIso,
    required this.contactSyncId,
  });
}

class _ReminderIsolatePayload {
  final List<_DebtReminderDto> debts;
  final Map<String, String> contactNames;

  const _ReminderIsolatePayload({
    required this.debts,
    required this.contactNames,
  });
}

class _ReminderCalculatedDto {
  final String id;
  final int debtId;
  final String title;
  final String message;
  final String type;
  final NotificationUrgency urgency;
  final String dueDateIso;
  final double remainingAmount;

  const _ReminderCalculatedDto({
    required this.id,
    required this.debtId,
    required this.title,
    required this.message,
    required this.type,
    required this.urgency,
    required this.dueDateIso,
    required this.remainingAmount,
  });
}

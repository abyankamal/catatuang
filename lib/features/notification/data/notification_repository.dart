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

    final rawDebts = unpaidDebts.map((d) => {
      'id': d.id,
      'syncId': d.syncId,
      'title': d.title,
      'type': d.type,
      'totalAmount': d.totalAmount,
      'paidAmount': d.paidAmount,
      'startDate': d.startDate.toIso8601String(),
      'dueDate': d.dueDate!.toIso8601String(),
      'contactSyncId': d.contactSyncId,
      'notes': d.notes,
      'isActive': d.isActive,
      'createdAt': d.createdAt.toIso8601String(),
      'updatedAt': d.updatedAt.toIso8601String(),
    }).toList();

    final rawContacts = contacts.map((c) => {
      'id': c.id,
      'syncId': c.syncId,
      'name': c.name,
      'phoneNumber': c.phoneNumber,
    }).toList();

    if (kIsWeb || rawDebts.length < 50) {
      return _computeReminders(rawDebts, rawContacts);
    }

    return await Isolate.run(() {
      return _computeReminders(rawDebts, rawContacts);
    });
  }

  static List<AppNotificationItem> _computeReminders(
    List<Map<String, dynamic>> rawDebts,
    List<Map<String, dynamic>> rawContacts,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final results = <AppNotificationItem>[];

    final contactMap = <String, Contact>{};
    for (final cData in rawContacts) {
      final contact = Contact()
        ..id = cData['id'] as int? ?? 0
        ..syncId = cData['syncId'] as String
        ..name = cData['name'] as String
        ..phoneNumber = cData['phoneNumber'] as String?;
      contactMap[contact.syncId] = contact;
    }

    for (final d in rawDebts) {
      final id = d['id'] as int;
      final title = d['title'] as String;
      final type = d['type'] as String;
      final totalAmount = d['totalAmount'] as double;
      final paidAmount = d['paidAmount'] as double;
      final remaining = totalAmount - paidAmount;
      final dueDate = DateTime.parse(d['dueDate'] as String);
      final dueDay = DateTime(dueDate.year, dueDate.month, dueDate.day);
      final contactSyncId = d['contactSyncId'] as String;

      final contact = contactMap[contactSyncId];
      final contactName = contact?.name ?? 'Pihak Terkait';
      final isPayable = type == 'PAYABLE';

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
            ? 'Utang "$title" ke $contactName sudah lewat $overdueDays hari.'
            : 'Tagihan "$title" ke $contactName sudah lewat $overdueDays hari.';
      } else if (diffDays == 0) {
        // Jatuh tempo hari ini
        urgency = NotificationUrgency.dueToday;
        notifTitle = isPayable ? 'Utang Jatuh Tempo Hari Ini' : 'Piutang Jatuh Tempo Hari Ini';
        notifMessage = isPayable
            ? 'Segera lunasi utang "$title" ke $contactName hari ini.'
            : 'Hari ini jadwal penagihan "$title" ke $contactName.';
      } else if (diffDays <= 3) {
        // Mendekati jatuh tempo (1 - 3 hari lagi)
        urgency = NotificationUrgency.upcoming;
        notifTitle = isPayable ? 'Pengingat Utang ($diffDays hari lagi)' : 'Pengingat Piutang ($diffDays hari lagi)';
        notifMessage = isPayable
            ? 'Utang "$title" ke $contactName jatuh tempo dalam $diffDays hari.'
            : 'Pinjaman "$title" ke $contactName jatuh tempo dalam $diffDays hari.';
      }

      if (urgency != null) {
        final debtObj = Debt()
          ..id = id
          ..syncId = d['syncId'] as String? ?? ''
          ..title = title
          ..type = type
          ..totalAmount = totalAmount
          ..paidAmount = paidAmount
          ..startDate = DateTime.tryParse(d['startDate'] as String? ?? '') ?? now
          ..dueDate = dueDate
          ..contactSyncId = contactSyncId
          ..notes = d['notes'] as String?
          ..isActive = d['isActive'] as bool? ?? true
          ..createdAt = DateTime.tryParse(d['createdAt'] as String? ?? '') ?? now
          ..updatedAt = DateTime.tryParse(d['updatedAt'] as String? ?? '') ?? now;

        results.add(
          AppNotificationItem(
            id: 'debt_reminder_$id',
            title: notifTitle,
            message: notifMessage,
            type: type,
            urgency: urgency,
            debtId: id,
            debt: debtObj,
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
}

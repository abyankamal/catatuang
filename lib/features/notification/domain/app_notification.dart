import '../../contact/domain/contact.dart';
import '../../debt/domain/debt.dart';
import '../../transaction/domain/recurring_transaction.dart';

enum NotificationUrgency {
  overdue, // Jatuh tempo sudah terlewat (Merah Pekat)
  dueToday, // Jatuh tempo hari ini (Merah/Mendesak)
  upcoming, // Mendekati jatuh tempo H-1 s.d. H-3 (Kuning)
}

class AppNotificationItem {
  final String id;
  final String title;
  final String message;
  final String type; // 'PAYABLE', 'RECEIVABLE', atau 'RECURRING'
  final NotificationUrgency urgency;
  final int? debtId;
  final Debt? debt;
  final Contact? contact;
  final RecurringTransaction? recurring;
  final DateTime dueDate;
  final double remainingAmount;

  const AppNotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.urgency,
    this.debtId,
    this.debt,
    this.contact,
    this.recurring,
    required this.dueDate,
    required this.remainingAmount,
  });

  bool get isRecurring => type == 'RECURRING' || recurring != null;
  bool get isPayable => type == 'PAYABLE';
  bool get isReceivable => type == 'RECEIVABLE';
}

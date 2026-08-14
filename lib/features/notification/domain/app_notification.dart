import '../../contact/domain/contact.dart';
import '../../debt/domain/debt.dart';

enum NotificationUrgency {
  overdue, // Jatuh tempo sudah terlewat (Merah Pekat)
  dueToday, // Jatuh tempo hari ini (Merah/Mendesak)
  upcoming, // Mendekati jatuh tempo H-1 s.d. H-3 (Kuning)
}

class AppNotificationItem {
  final String id;
  final String title;
  final String message;
  final String type; // 'PAYABLE' atau 'RECEIVABLE'
  final NotificationUrgency urgency;
  final int debtId;
  final Debt debt;
  final Contact? contact;
  final DateTime dueDate;
  final double remainingAmount;

  const AppNotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.urgency,
    required this.debtId,
    required this.debt,
    this.contact,
    required this.dueDate,
    required this.remainingAmount,
  });
}

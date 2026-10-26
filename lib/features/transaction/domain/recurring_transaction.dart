import 'package:isar/isar.dart';
import 'recurring_schedule_helper.dart';

part 'recurring_transaction.g.dart';

@Collection()
class RecurringTransaction {
  Id id = Isar.autoIncrement;

  RecurringTransaction();

  @Index(unique: true)
  late String syncId;

  @Index()
  late String type; // 'INCOME', 'EXPENSE', 'TRANSFER'

  late double amount;
  String? description;

  @Index()
  late String walletSyncId; // Dompet sumber
  String? targetWalletSyncId; // Dompet tujuan (khusus TRANSFER)
  String? categorySyncId;
  double? adminFee; // Biaya admin transfer jika ada

  late String frequency; // 'DAILY', 'WEEKLY', 'MONTHLY', 'YEARLY'
  int interval = 1;

  late DateTime startDate;
  DateTime? endDate;
  int? maxOccurrences;
  int occurrenceCount = 0;

  @Index()
  late DateTime nextDueDate;
  DateTime? lastExecutedDate;

  late bool autoExecute; // true: otomatis dieksekusi, false: minta konfirmasi
  late bool isActive; // soft-delete & pause/resume

  late DateTime createdAt;
  late DateTime updatedAt;

  @ignore
  bool get isCompleted => RecurringScheduleHelper.isCompleted(this);
}
